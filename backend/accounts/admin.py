from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, TechnicianProfile, CompanyProfile

class CustomUserAdmin(UserAdmin):
    fieldsets = UserAdmin.fieldsets + (
        ('Role Information', {'fields': ('role',)}),
    )
    list_display = ('username', 'email', 'role', 'is_staff')
    list_filter = ('role', 'is_staff', 'is_superuser', 'is_active')

@admin.register(TechnicianProfile)
class TechnicianProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'phone_number', 'is_verified', 'hourly_rate')
    search_fields = ('user__username', 'user__email', 'phone_number')
    list_filter = ('is_verified',)

@admin.register(CompanyProfile)
class CompanyProfileAdmin(admin.ModelAdmin):
    list_display = ('company_name', 'user', 'registration_number', 'is_verified')
    search_fields = ('company_name', 'user__username', 'registration_number')
    list_filter = ('is_verified', 'company_size')

admin.site.register(User, CustomUserAdmin)
