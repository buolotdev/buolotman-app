from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    dependencies = [
        ("governance", "0002_platformsetting"),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name="CmsPage",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("title", models.CharField(max_length=255)),
                ("slug", models.SlugField(unique=True)),
                ("excerpt", models.CharField(blank=True, max_length=300)),
                ("content", models.TextField(blank=True)),
                ("is_published", models.BooleanField(default=False)),
                ("show_in_footer", models.BooleanField(default=True)),
                ("sort_order", models.PositiveIntegerField(default=0)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                (
                    "updated_by",
                    models.ForeignKey(
                        blank=True,
                        null=True,
                        on_delete=django.db.models.deletion.SET_NULL,
                        related_name="updated_cms_pages",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
            ],
            options={
                "db_table": "governance_cms_page",
                "ordering": ["sort_order", "title"],
            },
        ),
        migrations.AddIndex(
            model_name="cmspage",
            index=models.Index(fields=["is_published"], name="governance_cms_ispub_idx"),
        ),
        migrations.AddIndex(
            model_name="cmspage",
            index=models.Index(fields=["show_in_footer"], name="governance_cms_footer_idx"),
        ),
        migrations.AddIndex(
            model_name="cmspage",
            index=models.Index(fields=["slug"], name="governance_cms_slug_idx"),
        ),
    ]
