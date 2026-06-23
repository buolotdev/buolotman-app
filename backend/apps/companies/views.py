from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response

from utils.cache import cached

from .models import CompanyProfile, CompanyProject, CompanyService, CompanyCertification, CompanyReview
from .serializers import (
    CompanyProfileSerializer, CompanyProjectSerializer,
    CompanyServiceSerializer, CompanyCertificationSerializer, CompanyReviewSerializer,
)


@api_view(['GET', 'PATCH'])
@permission_classes([IsAuthenticated])
def company_profile(request):
    try:
        profile = CompanyProfile.objects.get(user=request.user)
    except CompanyProfile.DoesNotExist:
        return Response({"error": "Company profile not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        serializer = CompanyProfileSerializer(profile)
        return Response(serializer.data)
    elif request.method == 'PATCH':
        serializer = CompanyProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([AllowAny])
def company_public_profile(request, company_id):
    try:
        profile = CompanyProfile.objects.get(id=company_id)
    except CompanyProfile.DoesNotExist:
        return Response({"error": "Company not found"}, status=status.HTTP_404_NOT_FOUND)

    data = CompanyProfileSerializer(profile).data
    data['projects'] = CompanyProjectSerializer(profile.projects.all()[:5], many=True).data
    data['services'] = CompanyServiceSerializer(profile.services.all(), many=True).data
    data['certifications'] = CompanyCertificationSerializer(profile.certifications.all(), many=True).data
    data['reviews'] = CompanyReviewSerializer(profile.reviews.all()[:10], many=True).data
    return Response(data)


@api_view(['GET'])
@permission_classes([AllowAny])
@cached("list_companies", ttl=120)
def list_companies(request):
    limit = int(request.query_params.get('limit', '12'))
    qs = CompanyProfile.objects.select_related('user').order_by('-created_at')[:max(1, min(limit, 50))]
    data = []
    for profile in qs:
        item = CompanyProfileSerializer(profile).data
        item['projects_count'] = profile.projects.count()
        item['services_count'] = profile.services.count()
        item['reviews_count'] = profile.reviews.count()
        data.append(item)
    return Response(data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def company_projects(request):
    try:
        profile = CompanyProfile.objects.get(user=request.user)
    except CompanyProfile.DoesNotExist:
        return Response({"error": "Company profile not found"}, status=status.HTTP_404_NOT_FOUND)

    projects = profile.projects.all()
    status_filter = request.query_params.get('status')
    if status_filter:
        projects = projects.filter(status=status_filter)
    serializer = CompanyProjectSerializer(projects, many=True)
    return Response(serializer.data)


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def company_services(request):
    try:
        profile = CompanyProfile.objects.get(user=request.user)
    except CompanyProfile.DoesNotExist:
        return Response({"error": "Company profile not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        services = profile.services.all()
        serializer = CompanyServiceSerializer(services, many=True)
        return Response(serializer.data)
    elif request.method == 'POST':
        serializer = CompanyServiceSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(company=profile)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_company_service(request, service_id):
    try:
        profile = CompanyProfile.objects.get(user=request.user)
    except CompanyProfile.DoesNotExist:
        return Response({"error": "Company profile not found"}, status=status.HTTP_404_NOT_FOUND)
    try:
        service = profile.services.get(id=service_id)
    except CompanyService.DoesNotExist:
        return Response({"error": "Service not found"}, status=status.HTTP_404_NOT_FOUND)
    service.delete()
    return Response(status=status.HTTP_204_NO_CONTENT)


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def company_projects_list_create(request):
    try:
        profile = CompanyProfile.objects.get(user=request.user)
    except CompanyProfile.DoesNotExist:
        return Response({"error": "Company profile not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        projects = profile.projects.all()
        serializer = CompanyProjectSerializer(projects, many=True)
        return Response(serializer.data)
    elif request.method == 'POST':
        serializer = CompanyProjectSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(company=profile)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def company_certifications_list_create(request):
    try:
        profile = CompanyProfile.objects.get(user=request.user)
    except CompanyProfile.DoesNotExist:
        return Response({"error": "Company profile not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        certs = profile.certifications.all()
        serializer = CompanyCertificationSerializer(certs, many=True)
        return Response(serializer.data)
    elif request.method == 'POST':
        serializer = CompanyCertificationSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(company=profile)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_company_review(request, company_id):
    try:
        profile = CompanyProfile.objects.get(id=company_id)
    except CompanyProfile.DoesNotExist:
        return Response({"error": "Company not found"}, status=status.HTTP_404_NOT_FOUND)

    from .serializers import CompanyReviewSerializer
    serializer = CompanyReviewSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    review = serializer.save(company=profile, reviewer=request.user)

    reviews = profile.reviews.all()
    total = sum(r.rating for r in reviews)
    profile.average_rating = round(total / reviews.count(), 2) if reviews.exists() else 0
    profile.review_count = reviews.count()
    profile.save(update_fields=['average_rating', 'review_count'])

    return Response(serializer.data, status=status.HTTP_201_CREATED)
