from django.contrib import admin
from .models import Task, Bid, Question, Category, Skill, TaskAttachment


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'slug', 'parent', 'is_active', 'order')
    prepopulated_fields = {'slug': ('name',)}
    list_filter = ('is_active', 'parent')
    search_fields = ('name',)


@admin.register(Skill)
class SkillAdmin(admin.ModelAdmin):
    list_display = ('name', 'slug', 'category')
    prepopulated_fields = {'slug': ('name',)}
    search_fields = ('name',)


@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = ('title', 'client', 'category', 'status', 'budget_min', 'budget_max', 'bids_count', 'created_at')
    list_filter = ('status', 'urgency', 'service_type', 'category')
    search_fields = ('title', 'description', 'client__email')
    raw_id_fields = ('client', 'assigned_to')


@admin.register(TaskAttachment)
class TaskAttachmentAdmin(admin.ModelAdmin):
    list_display = ('file_name', 'task', 'file_type', 'file_size')
    list_filter = ('file_type',)


@admin.register(Bid)
class BidAdmin(admin.ModelAdmin):
    list_display = ('task', 'technician', 'amount', 'status', 'created_at')
    list_filter = ('status', 'amount_type')
    search_fields = ('task__title', 'technician__email')


@admin.register(Question)
class QuestionAdmin(admin.ModelAdmin):
    list_display = ('task', 'asker', 'created_at', 'replied_at')
    search_fields = ('task__title', 'asker__email', 'text')
