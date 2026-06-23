from django.contrib import admin
from .models import CompanyProfile, CompanyProject, CompanyService, CompanyCertification, CompanyReview


@admin.register(CompanyProfile)
class CompanyProfileAdmin(admin.ModelAdmin):
    list_display = ('company_name', 'user', 'is_verified', 'average_rating', 'review_count', 'team_size')
    search_fields = ('company_name', 'user__email')
    list_filter = ('is_verified', 'company_size')


@admin.register(CompanyProject)
class CompanyProjectAdmin(admin.ModelAdmin):
    list_display = ('title', 'company', 'status', 'budget', 'progress', 'payment_status')
    list_filter = ('status', 'payment_status')
    search_fields = ('title', 'company__company_name')


@admin.register(CompanyService)
class CompanyServiceAdmin(admin.ModelAdmin):
    list_display = ('title', 'company')
    search_fields = ('title', 'company__company_name')


@admin.register(CompanyCertification)
class CompanyCertificationAdmin(admin.ModelAdmin):
    list_display = ('title', 'company')
    search_fields = ('title', 'company__company_name')


@admin.register(CompanyReview)
class CompanyReviewAdmin(admin.ModelAdmin):
    list_display = ('company', 'reviewer', 'rating', 'created_at')
    list_filter = ('rating',)
    search_fields = ('company__company_name', 'reviewer__email')
