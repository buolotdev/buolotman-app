from django.db import models
from django.contrib.auth.models import AbstractUser


class User(AbstractUser):
    ROLE_CHOICES = (
        ('CLIENT', 'Client'),
        ('TECHNICIAN', 'Technician'),
        ('COMPANY', 'Company'),
        ('ADMIN', 'Admin'),
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='CLIENT')
    phone = models.CharField(max_length=20, blank=True)
    avatar_url = models.URLField(blank=True, max_length=500)
    is_verified = models.BooleanField(default=False)
    language_preference = models.CharField(max_length=10, default='en')
    country = models.CharField(max_length=50, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'accounts_user'
        indexes = [
            models.Index(fields=['role']),
            models.Index(fields=['email']),
            models.Index(fields=['is_active']),
        ]

    def __str__(self):
        return f'{self.email} ({self.get_role_display()})'


class TechnicianProfile(models.Model):
    AVAILABILITY_CHOICES = (
        ('available', 'Available Today'),
        ('busy', 'Busy'),
        ('offline', 'Offline'),
    )
    BACKGROUND_CHECK_CHOICES = (
        ('pending', 'Pending'),
        ('passed', 'Passed'),
        ('failed', 'Failed'),
    )

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='technician_profile')
    bio = models.TextField(blank=True)
    phone_number = models.CharField(max_length=20, blank=True)
    hourly_rate = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    skills = models.ManyToManyField('tasks.Skill', blank=True, related_name='technicians')
    languages = models.JSONField(default=list, blank=True)
    portfolio = models.JSONField(default=list, blank=True)
    background_check_status = models.CharField(max_length=20, choices=BACKGROUND_CHECK_CHOICES, default='pending')
    is_verified = models.BooleanField(default=False)
    availability_status = models.CharField(max_length=20, choices=AVAILABILITY_CHOICES, default='available')
    completed_jobs = models.PositiveIntegerField(default=0)
    average_rating = models.DecimalField(max_digits=3, decimal_places=2, default=0)
    response_time = models.CharField(max_length=50, blank=True)

    class Meta:
        db_table = 'accounts_technician_profile'
        indexes = [
            models.Index(fields=['is_verified']),
            models.Index(fields=['availability_status']),
        ]

    def __str__(self):
        return f'{self.user.email} - Technician Profile'


class TechnicianService(models.Model):
    SERVICE_TYPE_CHOICES = (
        ("onsite", "On-site"),
        ("remote", "Remote"),
    )
    PRICING_MODEL_CHOICES = (
        ("fixed", "Fixed"),
        ("hourly", "Hourly"),
        ("range", "Range"),
    )

    technician = models.ForeignKey(User, on_delete=models.CASCADE, related_name="technician_services")
    title = models.CharField(max_length=255)
    category = models.ForeignKey("tasks.Category", on_delete=models.SET_NULL, null=True, blank=True, related_name="technician_services")
    description = models.TextField(blank=True)
    service_type = models.CharField(max_length=10, choices=SERVICE_TYPE_CHOICES, default="onsite")
    coverage_area = models.CharField(max_length=255, blank=True)
    pricing_model = models.CharField(max_length=10, choices=PRICING_MODEL_CHOICES, default="fixed")
    pricing_min = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    pricing_max = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "accounts_technician_service"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["service_type"]),
            models.Index(fields=["pricing_model"]),
            models.Index(fields=["is_active"]),
        ]

    def __str__(self):
        return self.title


class PortfolioItem(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='portfolio_items')
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    category = models.CharField(max_length=100, blank=True)
    image_url = models.URLField(blank=True, max_length=500)
    completed_date = models.DateField(null=True, blank=True)
    project_value = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'accounts_portfolio_item'
        ordering = ['-created_at']

    def __str__(self):
        return self.title


class SavedProfessional(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='saved_professionals')
    professional = models.ForeignKey(User, on_delete=models.CASCADE, related_name='saved_by', limit_choices_to={'role__in': ['TECHNICIAN', 'COMPANY']})
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'accounts_saved_professional'
        unique_together = ('user', 'professional')
        ordering = ['-created_at']


class PhoneOTPChallenge(models.Model):
    PURPOSE_CHOICES = (
        ('registration', 'Registration'),
        ('login', 'Login'),
        ('verification', 'Verification'),
        ('profile_change', 'Profile Change'),
    )

    user = models.ForeignKey(User, on_delete=models.CASCADE, null=True, blank=True, related_name='otp_challenges')
    phone = models.CharField(max_length=20)
    email = models.EmailField(blank=True)
    purpose = models.CharField(max_length=20, choices=PURPOSE_CHOICES, default='verification')
    code_hash = models.CharField(max_length=255)
    attempts = models.PositiveIntegerField(default=0)
    expires_at = models.DateTimeField()
    verified_at = models.DateTimeField(null=True, blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'accounts_phone_otp_challenge'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['phone']),
            models.Index(fields=['purpose']),
            models.Index(fields=['expires_at']),
        ]

    def __str__(self):
        return f'OTP {self.phone} ({self.purpose})'
