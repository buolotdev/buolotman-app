from rest_framework import status
from rest_framework.decorators import api_view, permission_classes, throttle_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView
from django.contrib.auth.hashers import check_password, make_password
from django.utils import timezone
from datetime import timedelta

from utils.cache import cached
from utils.rate_limit import (
    AuthLoginThrottle, AuthRegisterThrottle, UploadThrottle, rate_limit_otp,
)
from apps.governance.services import create_notification, create_audit_log
from utils.otp import generate_otp, send_otp

from .serializers import (
    CustomTokenObtainPairSerializer,
    ClientRegistrationSerializer,
    TechnicianRegistrationSerializer,
    CompanyRegistrationSerializer,
    UserMeSerializer,
    PortfolioItemSerializer,
    SavedProfessionalSerializer,
    TechnicianServiceSerializer,
)
from .models import PortfolioItem, SavedProfessional, PhoneOTPChallenge, TechnicianService


class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer
    throttle_classes = [AuthLoginThrottle]


@api_view(['POST'])
@rate_limit_otp
@permission_classes([AllowAny])
def request_phone_otp(request):
    phone = (request.data.get('phone') or '').strip()
    email = (request.data.get('email') or '').strip()
    purpose = (request.data.get('purpose') or 'verification').strip()

    if not phone:
        return Response({"error": "phone is required"}, status=status.HTTP_400_BAD_REQUEST)

    from django.contrib.auth import get_user_model
    User = get_user_model()
    user = None
    if email:
        user = User.objects.filter(email=email).first()
    if not user:
        user = User.objects.filter(phone=phone).first()

    code = generate_otp()
    challenge = PhoneOTPChallenge.objects.create(
        user=user,
        phone=phone,
        email=email,
        purpose=purpose if purpose in dict(PhoneOTPChallenge.PURPOSE_CHOICES) else 'verification',
        code_hash=make_password(code),
        expires_at=timezone.now() + timedelta(minutes=10),
        metadata={"requested_from": "api"},
    )
    send_otp(phone, code)

    return Response({
        "message": "OTP sent",
        "challenge_id": challenge.id,
        "expires_at": challenge.expires_at,
    })


@api_view(['POST'])
@rate_limit_otp
@permission_classes([AllowAny])
def verify_phone_otp(request):
    challenge_id = request.data.get('challenge_id')
    code = (request.data.get('code') or '').strip()

    if not challenge_id or not code:
        return Response({"error": "challenge_id and code are required"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        challenge = PhoneOTPChallenge.objects.select_related('user').get(id=challenge_id)
    except PhoneOTPChallenge.DoesNotExist:
        return Response({"error": "OTP challenge not found"}, status=status.HTTP_404_NOT_FOUND)

    if challenge.verified_at:
        return Response({"error": "OTP already verified"}, status=status.HTTP_400_BAD_REQUEST)
    if challenge.expires_at < timezone.now():
        return Response({"error": "OTP expired"}, status=status.HTTP_400_BAD_REQUEST)
    if challenge.attempts >= 5:
        return Response({"error": "Too many failed attempts"}, status=status.HTTP_429_TOO_MANY_REQUESTS)

    challenge.attempts += 1
    if not check_password(code, challenge.code_hash):
        challenge.save(update_fields=['attempts'])
        return Response({"error": "Invalid OTP"}, status=status.HTTP_400_BAD_REQUEST)

    challenge.verified_at = timezone.now()
    challenge.save(update_fields=['attempts', 'verified_at'])

    if challenge.user and not challenge.user.is_verified:
        challenge.user.is_verified = True
        challenge.user.save(update_fields=['is_verified'])
        create_audit_log(
            actor=challenge.user,
            action="phone_verified",
            entity_type="user",
            entity_id=challenge.user.id,
            summary=challenge.user.email,
            metadata={"challenge_id": challenge.id, "purpose": challenge.purpose},
            ip_address=request.META.get("REMOTE_ADDR"),
        )

    return Response({"message": "OTP verified", "verified": True, "purpose": challenge.purpose})


@api_view(['POST'])
@permission_classes([AllowAny])
@throttle_classes([AuthRegisterThrottle])
def register_client(request):
    serializer = ClientRegistrationSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        create_audit_log(
            actor=user,
            action="user_registered",
            entity_type="user",
            entity_id=user.id,
            summary="Client registration",
            metadata={"role": user.role},
            ip_address=request.META.get("REMOTE_ADDR"),
        )
        return Response({"message": "Client registered successfully."}, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
@throttle_classes([AuthRegisterThrottle])
def register_technician(request):
    serializer = TechnicianRegistrationSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        create_audit_log(
            actor=user,
            action="user_registered",
            entity_type="user",
            entity_id=user.id,
            summary="Technician registration",
            metadata={"role": user.role},
            ip_address=request.META.get("REMOTE_ADDR"),
        )
        return Response({"message": "Technician registered successfully. Awaiting verification."}, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
@throttle_classes([AuthRegisterThrottle])
def register_company(request):
    serializer = CompanyRegistrationSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        create_audit_log(
            actor=user,
            action="user_registered",
            entity_type="user",
            entity_id=user.id,
            summary="Company registration",
            metadata={"role": user.role},
            ip_address=request.META.get("REMOTE_ADDR"),
        )
        return Response({"message": "Company registered successfully. Awaiting verification."}, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'PATCH'])
@permission_classes([IsAuthenticated])
def me(request):
    if request.method == 'GET':
        serializer = UserMeSerializer(request.user)
        return Response(serializer.data)
    elif request.method == 'PATCH':
        serializer = UserMeSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([AllowAny])
@cached("list_users", ttl=120)
def list_users(request):
    from django.contrib.auth import get_user_model
    User = get_user_model()
    role = request.query_params.get('role', '').upper()
    limit = int(request.query_params.get('limit', '12'))
    qs = User.objects.filter(is_active=True)
    if role in ('TECHNICIAN', 'CLIENT', 'COMPANY', 'ADMIN'):
        qs = qs.filter(role=role)
    qs = qs.order_by('-created_at')[:max(1, min(limit, 50))]

    from .serializers import UserPublicSerializer
    data = []
    for user in qs:
        item = UserPublicSerializer(user).data
        if user.role == 'TECHNICIAN':
            profile = getattr(user, 'technician_profile', None)
            if profile:
                item['bio'] = profile.bio
                item['hourly_rate'] = str(profile.hourly_rate) if profile.hourly_rate else None
                item['skills'] = [s.name for s in profile.skills.all()]
                item['completed_jobs'] = profile.completed_jobs
                item['average_rating'] = str(profile.average_rating)
                item['availability_status'] = profile.availability_status
        data.append(item)
    return Response(data)


@api_view(['GET'])
@permission_classes([AllowAny])
def user_public_profile(request, user_id):
    from django.contrib.auth import get_user_model
    User = get_user_model()
    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)

    from .serializers import UserPublicSerializer
    serializer = UserPublicSerializer(user)
    data = serializer.data

    if user.role == 'TECHNICIAN':
        profile = getattr(user, 'technician_profile', None)
        if profile:
            data['bio'] = profile.bio
            data['hourly_rate'] = str(profile.hourly_rate) if profile.hourly_rate else None
            data['skills'] = [s.name for s in profile.skills.all()]
            data['languages'] = profile.languages
            data['completed_jobs'] = profile.completed_jobs
            data['average_rating'] = str(profile.average_rating)
            data['availability_status'] = profile.availability_status
            data['portfolio'] = profile.portfolio
            data['response_time'] = profile.response_time
    elif user.role == 'COMPANY':
        company = getattr(user, 'company_profile', None)
        if company:
            data['company_name'] = company.company_name
            data['registration_number'] = company.registration_number
            data['services_offered'] = company.services_offered
            data['company_size'] = company.company_size
            data['logo_url'] = company.logo_url
            data['cover_url'] = company.cover_url
            data['about'] = company.about
            data['website'] = company.website
            data['headquarters'] = company.headquarters
            data['business_hours'] = company.business_hours
            data['average_rating'] = str(company.average_rating)
            data['review_count'] = company.review_count
            data['team_size'] = company.team_size
            data['completed_tasks'] = company.completed_tasks
            data['response_time'] = company.response_time

    return Response(data)


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def portfolio_items(request):
    if request.method == 'GET':
        items = PortfolioItem.objects.filter(user=request.user)
        serializer = PortfolioItemSerializer(items, many=True)
        return Response(serializer.data)
    elif request.method == 'POST':
        serializer = PortfolioItemSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def portfolio_item_detail(request, item_id):
    try:
        item = PortfolioItem.objects.get(id=item_id, user=request.user)
    except PortfolioItem.DoesNotExist:
        return Response({"error": "Not found"}, status=status.HTTP_404_NOT_FOUND)
    item.delete()
    return Response(status=status.HTTP_204_NO_CONTENT)


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def saved_professionals(request):
    if request.method == 'GET':
        saved = SavedProfessional.objects.filter(user=request.user).select_related('professional')
        serializer = SavedProfessionalSerializer(saved, many=True)
        return Response(serializer.data)
    elif request.method == 'POST':
        professional_id = request.data.get('professional_id')
        if not professional_id:
            return Response({"error": "professional_id is required"}, status=status.HTTP_400_BAD_REQUEST)
        from django.contrib.auth import get_user_model
        User = get_user_model()
        try:
            professional = User.objects.get(id=professional_id, role__in=['TECHNICIAN', 'COMPANY'])
        except User.DoesNotExist:
            return Response({"error": "Professional not found"}, status=status.HTTP_404_NOT_FOUND)
        saved, created = SavedProfessional.objects.get_or_create(user=request.user, professional=professional)
        if not created:
            return Response({"message": "Already saved"}, status=status.HTTP_200_OK)
        return Response({"message": "Saved successfully"}, status=status.HTTP_201_CREATED)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def saved_professional_detail(request, professional_id):
    from django.contrib.auth import get_user_model
    User = get_user_model()
    try:
        professional = User.objects.get(id=professional_id)
    except User.DoesNotExist:
        return Response({"error": "Not found"}, status=status.HTTP_404_NOT_FOUND)
    deleted, _ = SavedProfessional.objects.filter(user=request.user, professional=professional).delete()
    if deleted:
        return Response(status=status.HTTP_204_NO_CONTENT)
    return Response({"error": "Not found"}, status=status.HTTP_404_NOT_FOUND)


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def technician_services(request):
    if request.user.role != "TECHNICIAN":
        return Response({"error": "Technician only"}, status=status.HTTP_403_FORBIDDEN)

    if request.method == 'GET':
        items = TechnicianService.objects.filter(technician=request.user).select_related('category')
        serializer = TechnicianServiceSerializer(items, many=True)
        return Response(serializer.data)

    serializer = TechnicianServiceSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    service = serializer.save(technician=request.user)
    create_audit_log(
        actor=request.user,
        action="technician_service_created",
        entity_type="technician_service",
        entity_id=service.id,
        summary=service.title,
        metadata={"service_type": service.service_type, "pricing_model": service.pricing_model},
        ip_address=request.META.get("REMOTE_ADDR"),
    )
    return Response(TechnicianServiceSerializer(service).data, status=status.HTTP_201_CREATED)


@api_view(['GET', 'PATCH', 'DELETE'])
@permission_classes([IsAuthenticated])
def technician_service_detail(request, service_id):
    if request.user.role != "TECHNICIAN":
        return Response({"error": "Technician only"}, status=status.HTTP_403_FORBIDDEN)
    try:
        service = TechnicianService.objects.select_related('category').get(id=service_id, technician=request.user)
    except TechnicianService.DoesNotExist:
        return Response({"error": "Service not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        return Response(TechnicianServiceSerializer(service).data)

    if request.method == 'DELETE':
        service.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    serializer = TechnicianServiceSerializer(service, data=request.data, partial=True)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    service = serializer.save()
    create_audit_log(
        actor=request.user,
        action="technician_service_updated",
        entity_type="technician_service",
        entity_id=service.id,
        summary=service.title,
        metadata={"service_type": service.service_type, "pricing_model": service.pricing_model},
        ip_address=request.META.get("REMOTE_ADDR"),
    )
    return Response(TechnicianServiceSerializer(service).data)


def _require_admin(request):
    if not request.user.is_authenticated or request.user.role != 'ADMIN':
        return Response({"error": "Admin only"}, status=status.HTTP_403_FORBIDDEN)
    return None


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def admin_verify_user(request, user_id):
    err = _require_admin(request)
    if err: return err
    from django.contrib.auth import get_user_model
    User = get_user_model()
    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)
    user.is_verified = True
    user.save(update_fields=['is_verified'])
    create_audit_log(
        actor=request.user,
        action="user_verified",
        entity_type="user",
        entity_id=user.id,
        summary=user.email,
        metadata={"verified": True},
        ip_address=request.META.get("REMOTE_ADDR"),
    )
    create_notification(
        user=user,
        category="verification",
        title="Account verified",
        body="Your account has been verified by the admin team.",
        link="/dashboard/client",
        metadata={"user_id": user.id},
    )
    return Response({"message": f"{user.email} verified", "is_verified": True})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def admin_suspend_user(request, user_id):
    err = _require_admin(request)
    if err: return err
    from django.contrib.auth import get_user_model
    User = get_user_model()
    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)
    action = request.data.get('action', 'suspend')
    if action == 'unsuspend':
        user.is_active = True
        user.save(update_fields=['is_active'])
        create_audit_log(
            actor=request.user,
            action="user_unsuspended",
            entity_type="user",
            entity_id=user.id,
            summary=user.email,
            metadata={"is_active": True},
            ip_address=request.META.get("REMOTE_ADDR"),
        )
        create_notification(
            user=user,
            category="system",
            title="Account reactivated",
            body="Your account has been reactivated.",
            link="/login",
            metadata={"user_id": user.id},
        )
        return Response({"message": f"{user.email} reactivated", "is_active": True})
    user.is_active = False
    user.save(update_fields=['is_active'])
    create_audit_log(
        actor=request.user,
        action="user_suspended",
        entity_type="user",
        entity_id=user.id,
        summary=user.email,
        metadata={"is_active": False},
        ip_address=request.META.get("REMOTE_ADDR"),
    )
    create_notification(
        user=user,
        category="system",
        title="Account suspended",
        body="Your account has been suspended by the admin team.",
        link="/login",
        metadata={"user_id": user.id},
    )
    return Response({"message": f"{user.email} suspended", "is_active": False})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def admin_list_users(request):
    err = _require_admin(request)
    if err: return err
    from django.contrib.auth import get_user_model
    User = get_user_model()
    qs = User.objects.all().order_by('-created_at')
    role = request.query_params.get('role', '').upper()
    if role in ('TECHNICIAN', 'CLIENT', 'COMPANY', 'ADMIN'):
        qs = qs.filter(role=role)
    verified = request.query_params.get('verified')
    if verified == 'true':
        qs = qs.filter(is_verified=True)
    elif verified == 'false':
        qs = qs.filter(is_verified=False)
    from .serializers import UserPublicSerializer
    return Response(UserPublicSerializer(qs, many=True).data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def admin_list_tasks(request):
    err = _require_admin(request)
    if err: return err
    from apps.tasks.models import Task
    from apps.tasks.serializers import TaskListSerializer
    qs = Task.objects.select_related('client', 'category').order_by('-created_at')
    status_filter = request.query_params.get('status')
    if status_filter:
        qs = qs.filter(status=status_filter)
    return Response(TaskListSerializer(qs, many=True).data)
