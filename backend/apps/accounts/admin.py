from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, TechnicianProfile, TechnicianService, PortfolioItem, SavedProfessional


class CustomUserAdmin(UserAdmin):
    fieldsets = UserAdmin.fieldsets + (
        ('Role Information', {'fields': ('role', 'phone', 'avatar_url', 'is_verified', 'language_preference', 'country')}),
    )
    list_display = ('username', 'email', 'role', 'is_verified', 'is_active', 'created_at')
    list_filter = ('role', 'is_verified', 'is_staff', 'is_superuser', 'is_active')
    search_fields = ('email', 'username', 'first_name', 'last_name')


@admin.register(TechnicianProfile)
class TechnicianProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'is_verified', 'hourly_rate', 'availability_status', 'completed_jobs', 'average_rating')
    search_fields = ('user__email', 'user__username', 'phone_number')
    list_filter = ('is_verified', 'availability_status', 'background_check_status')


@admin.register(PortfolioItem)
class PortfolioItemAdmin(admin.ModelAdmin):
    list_display = ('title', 'user', 'category', 'completed_date', 'project_value')
    search_fields = ('title', 'user__email')
    list_filter = ('category',)


@admin.register(TechnicianService)
class TechnicianServiceAdmin(admin.ModelAdmin):
    list_display = ('title', 'technician', 'category', 'service_type', 'pricing_model', 'is_active', 'created_at')
    list_filter = ('service_type', 'pricing_model', 'is_active', 'category')
    search_fields = ('title', 'description', 'technician__email')


@admin.register(SavedProfessional)
class SavedProfessionalAdmin(admin.ModelAdmin):
    list_display = ('user', 'professional', 'created_at')
    search_fields = ('user__email', 'professional__email')


admin.site.register(User, CustomUserAdmin)
