from django.core.management.base import BaseCommand
from apps.tasks.models import Category, Skill


CATEGORIES = [
    ("electrical", "Electrical", "Wiring, sockets, fans, lighting"),
    ("plumbing", "Plumbing", "Sinks, toilets, leaks, drainage"),
    ("hvac", "HVAC", "AC install, repair, servicing"),
    ("carpentry", "Carpentry", "Doors, shelves, furniture, fittings"),
    ("painting", "Painting", "Interior, exterior, wall finishing"),
    ("masonry", "Masonry", "Walls, tiling, concrete work"),
    ("security", "Security", "CCTV, alarms, access control"),
    ("cleaning", "Cleaning", "Home, office, deep cleaning"),
]

SKILLS = [
    "Wiring", "Fan installation", "Socket repair", "Lighting",
    "Pipe fitting", "Leak repair", "Drain cleaning", "Toilet install",
    "AC install", "AC servicing", "Refrigeration", "Ventilation",
    "Door fitting", "Shelving", "Furniture assembly", "Cabinet making",
    "Interior painting", "Exterior painting", "Wall prep", "Polishing",
    "Tiling", "Concrete", "Block laying", "Plastering",
    "CCTV install", "Alarm systems", "Access control", "Intercoms",
    "Home cleaning", "Office cleaning", "Deep cleaning", "Sanitation",
]


class Command(BaseCommand):
    help = "Seed the platform lookup data (categories and skills). Run this once after a fresh wipe."

    def handle(self, *args, **options):
        force = options.get("force", False)
        if not force and (Category.objects.exists() or Skill.objects.exists()):
            self.stdout.write(self.style.WARNING(
                "Categories or skills already exist. Pass --force to reseed."
            ))
            return

        for slug, name, desc in CATEGORIES:
            Category.objects.update_or_create(
                slug=slug,
                defaults={"name": name, "description": desc, "is_active": True},
            )
        self.stdout.write(self.style.SUCCESS(f"Seeded {len(CATEGORIES)} categories."))

        for name in SKILLS:
            slug = name.lower().replace(" ", "-")
            Skill.objects.update_or_create(slug=slug, defaults={"name": name})
        self.stdout.write(self.style.SUCCESS(f"Seeded {len(SKILLS)} skills."))

        self.stdout.write(self.style.SUCCESS("\nLookup data ready. No users, tasks, or transactions created."))
