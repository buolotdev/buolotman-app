from django.core.management.base import BaseCommand
from django.db import transaction
from django.contrib.auth import get_user_model

User = get_user_model()


class Command(BaseCommand):
    help = "Wipe ALL data from the database. Keeps the schema and migrations. Cannot be undone."

    def add_arguments(self, parser):
        parser.add_argument(
            "--yes",
            action="store_true",
            help="Skip the confirmation prompt.",
        )
        parser.add_argument(
            "--keep-admin",
            action="store_true",
            help="Keep admin@boulotman.com account if it exists.",
        )

    @transaction.atomic
    def handle(self, *args, **options):
        if not options["yes"]:
            self.stdout.write(self.style.WARNING(
                "\nThis will PERMANENTLY delete all users, profiles, tasks, bids, "
                "messages, transactions, companies, reviews, verifications, and files."
            ))
            confirm = input("Type 'WIPE' to confirm: ")
            if confirm.strip() != "WIPE":
                self.stdout.write(self.style.ERROR("Aborted."))
                return

        from apps.tasks.models import Task, Bid, Category, Skill, TaskAttachment
        from apps.wallet.models import Wallet, Transaction
        from apps.companies.models import (
            CompanyProfile, CompanyProject, CompanyService,
            CompanyCertification, CompanyReview,
        )
        from apps.messaging.models import Conversation, Message
        from apps.accounts.models import PortfolioItem, SavedProfessional

        kept_admin_ids = set()
        if options["keep_admin"]:
            kept_admin_ids = set(
                User.objects.filter(email="admin@boulotman.com").values_list("id", flat=True)
            )
            self.stdout.write(f"Keeping admin user (id={list(kept_admin_ids)}).")

        counts = {}

        counts["messages"] = Message.objects.all().delete()[0]
        counts["conversations"] = Conversation.objects.all().delete()[0]

        counts["transactions"] = Transaction.objects.all().delete()[0]
        counts["wallets"] = Wallet.objects.all().delete()[0]

        counts["bids"] = Bid.objects.all().delete()[0]
        counts["attachments"] = TaskAttachment.objects.all().delete()[0]
        counts["tasks"] = Task.objects.all().delete()[0]

        counts["categories"] = Category.objects.all().delete()[0]
        counts["skills"] = Skill.objects.all().delete()[0]

        counts["company_projects"] = CompanyProject.objects.all().delete()[0]
        counts["company_services"] = CompanyService.objects.all().delete()[0]
        counts["company_certs"] = CompanyCertification.objects.all().delete()[0]
        counts["company_reviews"] = CompanyReview.objects.all().delete()[0]
        counts["companies"] = CompanyProfile.objects.all().delete()[0]

        counts["portfolio"] = PortfolioItem.objects.all().delete()[0]
        counts["saved_pros"] = SavedProfessional.objects.all().delete()[0]

        users_qs = User.objects.exclude(id__in=kept_admin_ids) if kept_admin_ids else User.objects.all()
        counts["users"] = users_qs.delete()[0]

        self.stdout.write(self.style.SUCCESS("\nWiped:"))
        for k, v in counts.items():
            self.stdout.write(f"  {k:20s} {v}")
        self.stdout.write(self.style.SUCCESS("\nDatabase is now empty (except kept admin)."))
