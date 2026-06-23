from django.db import models
from django.conf import settings


class CompanyProfile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='company_profile')
    company_name = models.CharField(max_length=255)
    registration_number = models.CharField(max_length=100, blank=True)
    services_offered = models.JSONField(default=list, blank=True)
    company_size = models.CharField(max_length=50, blank=True)
    logo_url = models.URLField(blank=True, max_length=500)
    cover_url = models.URLField(blank=True, max_length=500)
    about = models.TextField(blank=True)
    website = models.URLField(blank=True)
    headquarters = models.CharField(max_length=255, blank=True)
    business_hours = models.JSONField(default=list, blank=True)
    is_verified = models.BooleanField(default=False)
    average_rating = models.DecimalField(max_digits=3, decimal_places=2, default=0)
    review_count = models.PositiveIntegerField(default=0)
    team_size = models.PositiveIntegerField(default=0)
    completed_tasks = models.PositiveIntegerField(default=0)
    response_time = models.CharField(max_length=50, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'companies_profile'
        verbose_name_plural = 'Company profiles'

    def __str__(self):
        return self.company_name


class CompanyProject(models.Model):
    STATUS_CHOICES = (
        ('active', 'Active'),
        ('pending', 'Pending Start'),
        ('completed', 'Completed'),
    )
    PAYMENT_STATUS_CHOICES = (
        ('funded', 'Funded in Escrow'),
        ('awaiting', 'Awaiting Deposit'),
        ('paid', 'Fully Paid'),
    )

    company = models.ForeignKey(CompanyProfile, on_delete=models.CASCADE, related_name='projects')
    title = models.CharField(max_length=255)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    client_name = models.CharField(max_length=255, blank=True)
    budget = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    timeline = models.CharField(max_length=255, blank=True)
    milestones_total = models.PositiveIntegerField(default=0)
    milestones_completed = models.PositiveIntegerField(default=0)
    payment_status = models.CharField(max_length=20, choices=PAYMENT_STATUS_CHOICES, default='awaiting')
    location = models.CharField(max_length=255, blank=True)
    progress = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'companies_project'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.title} - {self.company.company_name}'


class CompanyService(models.Model):
    company = models.ForeignKey(CompanyProfile, on_delete=models.CASCADE, related_name='services')
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'companies_service'
        ordering = ['title']

    def __str__(self):
        return self.title


class CompanyCertification(models.Model):
    company = models.ForeignKey(CompanyProfile, on_delete=models.CASCADE, related_name='certifications')
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'companies_certification'
        ordering = ['title']

    def __str__(self):
        return self.title


class CompanyReview(models.Model):
    company = models.ForeignKey(CompanyProfile, on_delete=models.CASCADE, related_name='reviews')
    reviewer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='company_reviews')
    rating = models.PositiveIntegerField()
    text = models.TextField(blank=True)
    service = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'companies_review'
        ordering = ['-created_at']

    def __str__(self):
        return f'Review by {self.reviewer.email} for {self.company.company_name}'
