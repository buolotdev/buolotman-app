from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('tasks', '0002_taskview'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.AddField(
            model_name='taskattachment',
            name='storage_key',
            field=models.CharField(blank=True, max_length=500),
        ),
        migrations.AddField(
            model_name='taskattachment',
            name='content_type',
            field=models.CharField(blank=True, max_length=100),
        ),
        migrations.AddField(
            model_name='taskattachment',
            name='uploaded_by',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='uploaded_attachments', to=settings.AUTH_USER_MODEL),
        ),
    ]
