from rest_framework import serializers
from .models import CompanyProfile, CompanyProject, CompanyService, CompanyCertification, CompanyReview


class CompanyProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = CompanyProfile
        fields = ['id', 'company_name', 'registration_number', 'services_offered', 'company_size',
                  'logo_url', 'cover_url', 'about', 'website', 'headquarters', 'business_hours',
                  'is_verified', 'average_rating', 'review_count', 'team_size', 'completed_tasks',
                  'response_time', 'created_at']
        read_only_fields = ['id', 'is_verified', 'average_rating', 'review_count', 'created_at']


class CompanyProjectSerializer(serializers.ModelSerializer):
    class Meta:
        model = CompanyProject
        fields = ['id', 'title', 'status', 'client_name', 'budget', 'timeline',
                  'milestones_total', 'milestones_completed', 'payment_status',
                  'location', 'progress', 'created_at']
        read_only_fields = ['id', 'created_at']


class CompanyServiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = CompanyService
        fields = ['id', 'title', 'description', 'created_at']
        read_only_fields = ['id', 'created_at']


class CompanyCertificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = CompanyCertification
        fields = ['id', 'title', 'description', 'created_at']
        read_only_fields = ['id', 'created_at']


class CompanyReviewSerializer(serializers.ModelSerializer):
    reviewer_name = serializers.SerializerMethodField()

    class Meta:
        model = CompanyReview
        fields = ['id', 'reviewer', 'reviewer_name', 'rating', 'text', 'service', 'created_at']
        read_only_fields = ['id', 'reviewer', 'created_at']

    def get_reviewer_name(self, obj):
        return f'{obj.reviewer.first_name} {obj.reviewer.last_name}'.strip() or obj.reviewer.email
