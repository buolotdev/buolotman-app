from django.db import migrations, models
from django.db.models import Q


class Migration(migrations.Migration):

    dependencies = [
        ("tasks", "0003_taskattachment_metadata"),
    ]

    operations = [
        migrations.AlterUniqueTogether(
            name="bid",
            unique_together=set(),
        ),
        migrations.AddConstraint(
            model_name="bid",
            constraint=models.UniqueConstraint(
                fields=("task", "technician"),
                condition=~Q(status="withdrawn"),
                name="tasks_bid_unique_active_per_task_technician",
            ),
        ),
    ]
