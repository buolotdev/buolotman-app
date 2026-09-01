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

    response_data = {
        "message": "OTP verified",
        "verified": True,
        "purpose": challenge.purpose,
    }
    if challenge.user:
        from rest_framework_simplejwt.tokens import RefreshToken
        refresh = RefreshToken.for_user(challenge.user)
        response_data["access"] = str(refresh.access_token)
        response_data["refresh"] = str(refresh)
        response_data["role"] = challenge.user.role

    return Response(response_data)


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
        data = serializer.data
        from apps.accounts.models import TechnicianProfile
        tech_profile, _ = TechnicianProfile.objects.get_or_create(user=request.user)
        data['bio'] = tech_profile.bio
        data['about'] = tech_profile.bio
        if request.user.role == 'TECHNICIAN':
            data['skills'] = [s.name for s in tech_profile.skills.all()]
            data['tools'] = tech_profile.languages if isinstance(tech_profile.languages, list) else []
            data['hourly_rate'] = str(tech_profile.hourly_rate) if tech_profile.hourly_rate else None
            data['response_time'] = tech_profile.response_time
            data['completed_jobs'] = tech_profile.completed_jobs
            data['average_rating'] = str(tech_profile.average_rating)
            data['availability_status'] = tech_profile.availability_status
            data['address'] = tech_profile.address
            data['date_of_birth'] = str(tech_profile.date_of_birth) if tech_profile.date_of_birth else None
            
            if tech_profile.portfolio and len(tech_profile.portfolio) > 0:
                data['portfolio'] = tech_profile.portfolio
            else:
                from apps.accounts.models import PortfolioItem
                items = PortfolioItem.objects.filter(user=request.user)
                if items.exists():
                    from .serializers import PortfolioItemSerializer
                    data['portfolio'] = PortfolioItemSerializer(items, many=True).data
                else:
                    data['portfolio'] = []
        return Response(data)
    elif request.method == 'PATCH':
        role_to_set = request.data.get('role')
        if role_to_set and str(role_to_set).upper() in ['CLIENT', 'TECHNICIAN', 'COMPANY']:
            new_role = str(role_to_set).upper()
            request.user.role = new_role
            request.user.save(update_fields=['role'])
            
        user_update_data = {}
        for k in ['first_name', 'last_name', 'phone', 'avatar_url', 'banner_url', 'language_preference', 'country', 'address', 'education_level', 'expertise_level']:
            if k in request.data:
                user_update_data[k] = request.data[k]
        
        # Flattened payload support
        if 'city' in request.data and 'address' not in request.data:
            user_update_data['address'] = request.data['city']

        if 'date_of_birth' in request.data:
            dob = request.data.get('date_of_birth')
            user_update_data['date_of_birth'] = dob if dob else None

        serializer = UserMeSerializer(request.user, data=user_update_data, partial=True)
        if serializer.is_valid():
            serializer.save()

        # Update TechnicianProfile bio/about for all users, plus technician-specific fields
        from apps.accounts.models import TechnicianProfile
        tech_profile, _ = TechnicianProfile.objects.get_or_create(user=request.user)
        
        tech_data = request.data.get('technician_profile') or {}
        bio = request.data.get('bio') or request.data.get('about') or tech_data.get('bio') or tech_data.get('about')
        if bio is not None:
            tech_profile.bio = str(bio)

        if 'hourly_rate' in request.data or 'hourly_rate' in tech_data:
            hr_val = request.data.get('hourly_rate') or tech_data.get('hourly_rate')
            if hr_val:
                clean_hr = ''.join(c for c in str(hr_val) if c.isdigit() or c == '.')
                tech_profile.hourly_rate = float(clean_hr) if clean_hr else None
            else:
                tech_profile.hourly_rate = None
                
        if 'response_time' in request.data or 'response_time' in tech_data:
            tech_profile.response_time = str(request.data.get('response_time') or tech_data.get('response_time') or '')
            
        if 'tools' in request.data or 'tools' in tech_data:
            tools_val = request.data.get('tools') or tech_data.get('tools') or []
            tech_profile.languages = tools_val if isinstance(tools_val, list) else []
        elif 'languages' in request.data:
            tech_profile.languages = request.data.get('languages') or []
            
        if 'portfolio' in request.data or 'portfolio' in tech_data:
            port_val = request.data.get('portfolio') or tech_data.get('portfolio') or []
            tech_profile.portfolio = port_val if isinstance(port_val, list) else []
            
        if 'skills' in request.data or 'skills' in tech_data:
            skill_items = request.data.get('skills') or tech_data.get('skills') or []
            if isinstance(skill_items, list):
                from apps.tasks.models import Skill
                tech_profile.skills.clear()
                for item in skill_items:
                    s_name = item.get('name') if isinstance(item, dict) else (str(item) if item else "")
                    if s_name and s_name.strip():
                        skill_obj, _ = Skill.objects.get_or_create(name=s_name.strip())
                        tech_profile.skills.add(skill_obj)
                        
        # ALL PREMIUM FIELDS
        premium_fields = ['address', 'date_of_birth', 'years_experience', 'primary_occupation', 'certifications', 'licences', 'education_level', 'expertise_level', 'business_type', 'daily_rate', 'fixed_price', 'inspection_fee', 'starting_price', 'own_tools', 'has_vehicle', 'has_ppe', 'has_specialist_machinery', 'has_driving_licence', 'can_transport_equipment', 'willing_to_travel', 'service_radius_km', 'available_now', 'accepts_full_time', 'accepts_part_time', 'accepts_emergency', 'accepts_weekends', 'accepts_remote', 'accepts_onsite', 'bm_concierge', 'bm_build_team', 'bm_emergency', 'bm_contractor_projects', 'can_supervise', 'team_leader_experience', 'project_management_experience', 'interested_in_long_term_placement', 'national_id_number', 'national_id_front', 'national_id_back', 'selfie_url', 'emergency_contact_name', 'emergency_contact_phone', 'preferred_payout_method', 'bank_account_name', 'bank_account_number', 'bank_name', 'mobile_money_number', 'payout_currency', 'payment_verification_status', 'tools_and_equipment', 'work_preferences', 'preferred_working_days', 'preferred_working_hours']
        
        for field in premium_fields:
            if field in request.data:
                val = request.data.get(field)
                if val == "":
                    val = None if field in ['date_of_birth', 'daily_rate', 'fixed_price', 'inspection_fee', 'starting_price'] else ""
                setattr(tech_profile, field, val)

        if 'city' in request.data and 'address' not in request.data:
            tech_profile.address = request.data.get('city') or ''

        tech_profile.save()

        res_serializer = UserMeSerializer(request.user)
        res_data = res_serializer.data
        res_data['bio'] = tech_profile.bio
        res_data['about'] = tech_profile.bio
        if request.user.role == 'TECHNICIAN':
            res_data['skills'] = [s.name for s in tech_profile.skills.all()]
            res_data['tools'] = tech_profile.languages if isinstance(tech_profile.languages, list) else []
            res_data['portfolio'] = tech_profile.portfolio
            res_data['hourly_rate'] = str(tech_profile.hourly_rate) if tech_profile.hourly_rate else None
            res_data['response_time'] = tech_profile.response_time
            res_data['address'] = tech_profile.address
            res_data['date_of_birth'] = str(tech_profile.date_of_birth) if tech_profile.date_of_birth else None
            
        return Response(res_data)


@api_view(['GET'])
@permission_classes([AllowAny])
def list_users(request):
    from django.contrib.auth import get_user_model
    User = get_user_model()
    role = request.query_params.get('role', '').upper()
    limit = int(request.query_params.get('limit', '12'))
    qs = User.objects.filter(is_active=True).select_related('technician_profile', 'company_profile').prefetch_related('technician_services', 'technician_profile__skills')
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
    qs = User.objects.all().select_related('technician_profile', 'company_profile').prefetch_related('technician_services', 'technician_profile__skills').order_by('-created_at')
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
