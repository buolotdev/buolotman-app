from decimal import Decimal, InvalidOperation

from django.db.models import Q
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from apps.accounts.models import User
from apps.accounts.models import TechnicianService
from apps.accounts.serializers import UserPublicSerializer
from apps.companies.models import CompanyProfile
from apps.companies.serializers import CompanyProfileSerializer
from apps.tasks.models import Task
from apps.tasks.serializers import TaskListSerializer


def _parse_decimal(value):
    if value in (None, ""):
        return None
    try:
        return Decimal(str(value))
    except (InvalidOperation, ValueError):
        return None


@api_view(['GET'])
@permission_classes([AllowAny])
def search(request):
    query = (request.query_params.get('q') or '').strip()
    category = (request.query_params.get('category') or '').strip()
    location = (request.query_params.get('location') or '').strip()
    professional_type = (request.query_params.get('professionalType') or request.query_params.get('type') or 'all').strip().lower()
    tab = (request.query_params.get('tab') or 'all').strip().lower()
    sort = (request.query_params.get('sort') or 'relevance').strip().lower()
    min_rating = _parse_decimal(request.query_params.get('rating') or request.query_params.get('min_rating'))
    budget_min = _parse_decimal(request.query_params.get('budgetMin') or request.query_params.get('budget_min'))
    budget_max = _parse_decimal(request.query_params.get('budgetMax') or request.query_params.get('budget_max'))
    include_tasks = tab in ('all', 'tasks')
    include_services = tab in ('all', 'services')
    include_technicians = professional_type in ('all', 'technician', 'professionals')
    include_companies = professional_type in ('all', 'company', 'companies', 'professionals')

    tasks = Task.objects.select_related('client', 'category').prefetch_related('skills').filter(status='open')
    if query:
        tasks = tasks.filter(Q(title__icontains=query) | Q(description__icontains=query) | Q(location__icontains=query) | Q(city__icontains=query))
    if category:
        tasks = tasks.filter(Q(category__slug__iexact=category) | Q(category__name__icontains=category))
    if location:
        tasks = tasks.filter(Q(location__icontains=location) | Q(city__icontains=location))
    if budget_min is not None:
        tasks = tasks.filter(budget_max__gte=budget_min)
    if budget_max is not None:
        tasks = tasks.filter(budget_min__lte=budget_max)
    if sort == 'budget_high':
        tasks = tasks.order_by('-budget_max', '-created_at')
    elif sort == 'budget_low':
        tasks = tasks.order_by('budget_min', '-created_at')
    else:
        tasks = tasks.order_by('-created_at')

    users = User.objects.filter(is_active=True, role='TECHNICIAN').select_related('technician_profile').prefetch_related('technician_profile__skills')
    if query:
        users = users.filter(Q(first_name__icontains=query) | Q(last_name__icontains=query) | Q(username__icontains=query) | Q(email__icontains=query))
    if location:
        users = users.filter(Q(country__icontains=location) | Q(technician_profile__languages__icontains=location))
    if min_rating is not None:
        users = users.filter(technician_profile__average_rating__gte=min_rating)

    companies = CompanyProfile.objects.select_related('user').prefetch_related('services', 'reviews').order_by('-created_at')
    if query:
        companies = companies.filter(Q(company_name__icontains=query) | Q(about__icontains=query) | Q(headquarters__icontains=query))
    if location:
        companies = companies.filter(Q(headquarters__icontains=location) | Q(user__country__icontains=location))
    if min_rating is not None:
        companies = companies.filter(average_rating__gte=min_rating)

    services = TechnicianService.objects.select_related('technician', 'category').filter(is_active=True)
    if query:
        services = services.filter(
            Q(title__icontains=query)
            | Q(description__icontains=query)
            | Q(coverage_area__icontains=query)
            | Q(category__name__icontains=query)
            | Q(technician__first_name__icontains=query)
            | Q(technician__last_name__icontains=query)
            | Q(technician__username__icontains=query)
        )
    if category:
        services = services.filter(Q(category__slug__iexact=category) | Q(category__name__icontains=category))
    if location:
        services = services.filter(Q(coverage_area__icontains=location) | Q(technician__country__icontains=location))
    if min_rating is not None:
        services = services.filter(technician__technician_profile__average_rating__gte=min_rating)

    results = []
    if include_tasks:
        for task in tasks[:25]:
            payload = TaskListSerializer(task).data
            payload['type'] = 'task'
            payload['name'] = payload.get('title', '')
            payload['description'] = task.description
            payload['location'] = task.city or task.location or ''
            payload['rating'] = None
            payload['reviews_count'] = task.bids_count
            payload['price'] = task.budget_min if task.budget_min is not None else task.budget_max
            results.append(payload)

    if include_services:
        for service in services[:25]:
            profile = getattr(service.technician, 'technician_profile', None)
            results.append({
                'id': service.id,
                'type': 'service',
                'name': service.title,
                'role': f"{service.technician.first_name} {service.technician.last_name}".strip() or service.technician.username,
                'description': service.description,
                'image': service.technician.avatar_url,
                'category': service.category.name if service.category else '',
                'rating': float(profile.average_rating) if profile else None,
                'reviews': profile.completed_jobs if profile else 0,
                'location': service.coverage_area or service.technician.country or '',
                'price': float(service.pricing_min) if service.pricing_min is not None else None,
                'priceLabel': service.pricing_model,
                'verified': bool(service.technician.is_verified or (profile and profile.is_verified)),
                'skills': [skill.name for skill in profile.skills.all()] if profile else [],
                'serviceType': service.service_type,
                'pricingModel': service.pricing_model,
                'profileId': service.technician.id,
            })

    if include_technicians and tab in ('all', 'technician', 'technicians', 'professionals'):
        for user in users[:25]:
            base = UserPublicSerializer(user).data
            if user.role == 'TECHNICIAN':
                profile = getattr(user, 'technician_profile', None)
                results.append({
                    'id': user.id,
                    'type': 'technician',
                    'name': f"{user.first_name} {user.last_name}".strip() or user.username,
                    'role': 'Technician',
                    'description': profile.bio if profile else '',
                    'image': user.avatar_url,
                    'category': '',
                    'rating': float(profile.average_rating) if profile else None,
                    'reviews': profile.completed_jobs if profile else 0,
                    'location': user.country or '',
                    'price': float(profile.hourly_rate) if profile and profile.hourly_rate is not None else None,
                    'priceLabel': 'hourly rate',
                    'verified': bool(user.is_verified or (profile and profile.is_verified)),
                    'skills': [skill.name for skill in profile.skills.all()] if profile else [],
                    'profile': base,
                })
    if include_companies and tab in ('all', 'companies', 'professionals'):
        for company in companies[:25]:
            results.append({
                'id': company.user.id,
                'type': 'company',
                'name': company.company_name,
                'role': 'Company',
                'description': company.about,
                'image': company.logo_url or company.user.avatar_url,
                'category': '',
                'rating': float(company.average_rating),
                'reviews': company.review_count,
                'location': company.headquarters or company.user.country or '',
                'price': None,
                'priceLabel': 'company profile',
                'verified': bool(company.is_verified or company.user.is_verified),
                'skills': company.services_offered if isinstance(company.services_offered, list) else [],
            })

    page = max(1, int(request.query_params.get('page', 1)))
    limit = min(50, max(1, int(request.query_params.get('limit', 20))))
    start = (page - 1) * limit
    end = start + limit
    paginated = results[start:end]

    return Response({
        'results': paginated,
        'total': len(results),
        'page': page,
        'limit': limit,
        'total_pages': (len(results) + limit - 1) // limit,
    })
