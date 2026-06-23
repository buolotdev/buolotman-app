from django.db import models
from django.conf import settings
from django.db.models import Q


class Category(models.Model):
    name = models.CharField(max_length=100)
    slug = models.SlugField(unique=True)
    icon = models.CharField(max_length=50, blank=True)
    parent = models.ForeignKey('self', on_delete=models.CASCADE, null=True, blank=True, related_name='subcategories')
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    order = models.PositiveIntegerField(default=0)

    class Meta:
        db_table = 'tasks_category'
        ordering = ['order', 'name']
        verbose_name_plural = 'categories'

    def __str__(self):
        return self.name


class Skill(models.Model):
    name = models.CharField(max_length=100)
    slug = models.SlugField(unique=True)
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, blank=True, related_name='skills')

    class Meta:
        db_table = 'tasks_skill'
        ordering = ['name']

    def __str__(self):
        return self.name


class Task(models.Model):
    STATUS_CHOICES = (
        ('draft', 'Draft'),
        ('open', 'Open'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    )
    BUDGET_MODE_CHOICES = (
        ('fixed', 'Fixed'),
        ('hourly', 'Hourly'),
    )
    URGENCY_CHOICES = (
        ('urgent', 'Urgent'),
        ('standard', 'Standard'),
    )
    SERVICE_TYPE_CHOICES = (
        ('onsite', 'On-site'),
        ('remote', 'Remote'),
        ('hybrid', 'Hybrid'),
    )

    id = models.AutoField(primary_key=True)
    title = models.CharField(max_length=255)
    description = models.TextField()
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, related_name='tasks')
    client = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='client_tasks')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    budget_min = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    budget_max = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    budget_mode = models.CharField(max_length=10, choices=BUDGET_MODE_CHOICES, default='fixed')
    urgency = models.CharField(max_length=10, choices=URGENCY_CHOICES, default='standard')
    service_type = models.CharField(max_length=10, choices=SERVICE_TYPE_CHOICES, default='onsite')
    location = models.CharField(max_length=255, blank=True)
    city = models.CharField(max_length=100, blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    schedule = models.CharField(max_length=255, blank=True)
    deadline = models.DateField(null=True, blank=True)
    materials_provided = models.BooleanField(default=False)
    contact_methods = models.JSONField(default=list, blank=True)
    skills = models.ManyToManyField(Skill, blank=True, related_name='tasks')
    views_count = models.PositiveIntegerField(default=0)
    bids_count = models.PositiveIntegerField(default=0)
    assigned_to = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_tasks')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    published_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'tasks_task'
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['category']),
            models.Index(fields=['client']),
            models.Index(fields=['-created_at']),
            models.Index(fields=['city']),
        ]
        ordering = ['-created_at']

    def __str__(self):
        return self.title


class TaskView(models.Model):
    task = models.ForeignKey(Task, on_delete=models.CASCADE, related_name='task_views')
    viewer_ip = models.GenericIPAddressField()
    viewed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'tasks_task_view'
        unique_together = ('task', 'viewer_ip')

    def __str__(self):
        return f"View of {self.task_id} from {self.viewer_ip}"


class TaskAttachment(models.Model):
    FILE_TYPE_CHOICES = (
        ('image', 'Image'),
        ('file', 'File'),
    )

    task = models.ForeignKey(Task, on_delete=models.CASCADE, related_name='attachments')
    file_url = models.URLField(max_length=500)
    storage_key = models.CharField(max_length=500, blank=True)
    file_name = models.CharField(max_length=255)
    file_type = models.CharField(max_length=10, choices=FILE_TYPE_CHOICES, default='file')
    file_size = models.PositiveIntegerField(default=0)
    content_type = models.CharField(max_length=100, blank=True)
    uploaded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='uploaded_attachments')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'tasks_task_attachment'
        ordering = ['created_at']

    def __str__(self):
        return self.file_name


class Bid(models.Model):
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('shortlisted', 'Shortlisted'),
        ('accepted', 'Accepted'),
        ('rejected', 'Rejected'),
        ('withdrawn', 'Withdrawn'),
    )
    AMOUNT_TYPE_CHOICES = (
        ('fixed', 'Fixed Quote'),
        ('hourly', 'Hourly Rate'),
    )

    id = models.AutoField(primary_key=True)
    task = models.ForeignKey(Task, on_delete=models.CASCADE, related_name='bids')
    technician = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='technician_bids')
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    amount_type = models.CharField(max_length=10, choices=AMOUNT_TYPE_CHOICES, default='fixed')
    message = models.TextField()
    duration = models.CharField(max_length=100, blank=True)
    extra_notes = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    accepted_at = models.DateTimeField(null=True, blank=True)
    rejected_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'tasks_bid'
        indexes = [
            models.Index(fields=['task']),
            models.Index(fields=['technician']),
            models.Index(fields=['status']),
            models.Index(fields=['-created_at']),
        ]
        constraints = [
            models.UniqueConstraint(
                fields=['task', 'technician'],
                condition=~Q(status='withdrawn'),
                name='tasks_bid_unique_active_per_task_technician',
            ),
        ]
        ordering = ['-created_at']

    def __str__(self):
        return f'Bid by {self.technician.email} on {self.task.title}'


class Question(models.Model):
    task = models.ForeignKey(Task, on_delete=models.CASCADE, related_name='questions')
    asker = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='asked_questions')
    text = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    reply_text = models.TextField(blank=True)
    replied_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='replied_questions')
    replied_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'tasks_question'
        indexes = [
            models.Index(fields=['task']),
            models.Index(fields=['-created_at']),
        ]
        ordering = ['-created_at']

    def __str__(self):
        return f'Question on {self.task.title}'
