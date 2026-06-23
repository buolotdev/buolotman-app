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



class TechnicianProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='technician_profile')
    phone_number = models.CharField(max_length=20, blank=True)
    skills = models.TextField(blank=True, help_text="Comma separated skills")
    is_verified = models.BooleanField(default=False)
    hourly_rate = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)

    def __str__(self):
        return f"{self.user.username} - Technician"

class CompanyProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='company_profile')
    company_name = models.CharField(max_length=255)
    registration_number = models.CharField(max_length=100, blank=True)
    services_offered = models.TextField(blank=True, help_text="Comma separated services")
    company_size = models.CharField(max_length=50, blank=True)
    is_verified = models.BooleanField(default=False)

    def __str__(self):
        return self.company_name
