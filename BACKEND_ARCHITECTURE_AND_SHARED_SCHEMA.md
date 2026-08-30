# Boulot Man: Backend Architecture and Shared Database Contract

## Scope and source of truth

The active backend is Django REST Framework under `backend/config` and `backend/apps/*`. The frontend is Next.js and calls that API. `backend/core` and the top-level `backend/accounts` tree are legacy/unwired code, not part of the active Django project.

This document describes the schema declared by the latest migrations and models in this repository. It is not a dump of the deployed database: production access was not available. Before shipping a mobile client, compare `python manage.py showmigrations` and the production database schema with this document.

## Product model

Boulot Man is a services marketplace with four account roles:

* `CLIENT` posts a task, receives bids, selects a provider, funds/releases a nominal escrow record, can communicate, dispute, and obtain support.
* `TECHNICIAN` maintains a profile, portfolio, verification documents and service listings, finds tasks, bids, performs assigned work, and withdraws wallet balance.
* `COMPANY` owns a public company profile plus separate company projects, services, certifications, reviews, quote requests, activities and team-member records. A company can also submit task bids.
* `ADMIN` is expected to verify/suspend users and operate governance, disputes, CMS, content, support and transaction dashboards.

The canonical task assignment relationship is `tasks_task.assigned_to_id -> accounts_user.id`. Do not introduce a separate technician field in mobile clients.

## Shared client contract

Both web and mobile must use the same user ID, JWT identity, database IDs and status strings. Do not duplicate marketplace state in either client.

* Authentication: bearer JWT access token and refresh token. Login returns role and basic profile data.
* Identity: a user has one current `role`, but role switching is currently permitted. Treat profile type as data attached to the same `accounts_user` ID, not as a new account.
* Task statuses are lowercase: `draft`, `open`, `in_progress`, `completed`, `cancelled`.
* Bid statuses are lowercase: `pending`, `shortlisted`, `accepted`, `rejected`, `withdrawn`.
* Wallet transaction types: `credit`, `debit`, `pending`; categories: `earnings`, `withdrawal`, `escrow_hold`, `escrow_release`, `refund`.
* Milestone status strings are title case: `Pending`, `Awaiting Execution`, `Awaiting Client`, `Released`.
* Task review status strings are title case: `Published`, `Pending Review`, `Hidden`.
* Company project statuses are `active`, `pending`, `completed`; company-project payment status is `funded`, `awaiting`, `paid`.
* Treat timestamps as UTC ISO 8601 values. Decimal money fields should be sent and handled as strings, never IEEE-754 floating-point values.

## Location and IP behavior

There is no IP geolocation or country/city derivation. Task discovery can filter by user-supplied `city`; global search matches task `location`/`city`, technician `country`/coverage area, and company headquarters/country. Country and city are plain strings, so this is text search, not a geographic-radius system.

The only persisted IP feature is `tasks_task_view`: reading a task records one view per task/client IP and increments `views_count`. The API trusts `X-Forwarded-For`; it is not a trustworthy anti-fraud or location signal. Audit records store `REMOTE_ADDR` for selected actions. There is no IP risk scoring, device tracking, geo fencing, proximity search, country access policy, or fraud prevention.

For a Fiverr-like seamless experience, mobile should send the same location fields used by web, preserve user-entered country/city, and refresh list/search results from the API. It should not infer a country from IP and write it back without explicit user consent.

## Marketplace workflow

1. A verified client creates a task (`draft` or `open`) with budget, service, location, schedule, skills and optional attachments. A draft may be published to `open`.
2. Open, unassigned tasks appear in task listing/search. Technicians and companies must be verified to submit a bid. A database constraint permits one active bid per provider/task.
3. The client accepts or rejects a bid. Acceptance assigns `task.assigned_to`, changes the task to `in_progress`, and records `accepted_at`.
4. The assigned provider should submit a deliverable. The client can complete the task; a separate wallet call releases escrow and credits the assignee.
5. Messages, notifications, evidence, disputes, support tickets and reviews attach to the same user/task identifiers.

Current implementation warning: the wallet is an internal ledger, not payment processing. There is no Stripe, bank, mobile-money or payout integration.

## Application tables

### Accounts

| Table | Columns and relationships |
| --- | --- |
| `accounts_user` | Django user fields (`id`, password hash, last_login, is_superuser, username, first/last name, email, is_staff, is_active, date_joined) plus `role`, `phone`, `avatar_url`, `banner_url`, `is_verified`, `language_preference`, `country`, `date_of_birth`, `address`, `education_level`, `expertise_level`, `created_at`, `updated_at`. Roles: CLIENT/TECHNICIAN/COMPANY/ADMIN. |
| `accounts_technician_profile` | `id`, one-to-one `user_id`, `bio`, `phone_number`, `hourly_rate`, `languages` JSON, `portfolio` JSON, `background_check_status`, `is_verified`, `availability_status`, `completed_jobs`, `average_rating`, `response_time`. |
| `accounts_technician_profile_skills` | Django M2M join between technician profile and `tasks_skill`. |
| `accounts_technician_service` | `id`, `technician_id -> accounts_user`, optional `category_id -> tasks_category`, `title`, `description`, `service_type`, `coverage_area`, `pricing_model`, `pricing_min`, `pricing_max`, `media` JSON, `is_active`, timestamps. |
| `accounts_portfolio_item` | `id`, `user_id`, `title`, `description`, `category`, `image_url`, `completed_date`, `project_value`, `created_at`. |
| `accounts_saved_professional` | `id`, `user_id`, `professional_id -> accounts_user`, `created_at`; unique `(user_id, professional_id)`. |
| `accounts_phone_otp_challenge` | `id`, nullable `user_id`, `phone`, `email`, `purpose`, `code_hash`, `attempts`, `expires_at`, `verified_at`, `metadata` JSON, `created_at`. |
| `accounts_technician_document` | `id`, `user_id`, `title`, `document_type`, `file_url`, `is_verified`, `created_at`. |

### Taxonomy and tasks

| Table | Columns and relationships |
| --- | --- |
| `tasks_category` | `id`, `name`, unique `slug`, `icon`, nullable self-FK `parent_id`, `description`, `is_active`, `order`. Parent/child hierarchy. |
| `tasks_skill` | `id`, `name`, unique `slug`, nullable `category_id -> tasks_category`. |
| `tasks_task` | `id`, `title`, `description`, nullable `category_id`, `client_id -> accounts_user`, `status`, `budget_min`, `budget_max`, `budget_mode`, `urgency`, `service_type`, `location`, `city`, `latitude`, `longitude`, `schedule`, `deadline`, `materials_provided`, `contact_methods` JSON, `views_count`, `bids_count`, nullable `assigned_to_id -> accounts_user`, timestamps, nullable `published_at`. |
| `tasks_task_skills` | Django M2M join between task and skill. |
| `tasks_task_view` | `id`, `task_id`, `viewer_ip`, `viewed_at`; unique `(task_id, viewer_ip)`. |
| `tasks_task_attachment` | `id`, `task_id`, `file_url`, `storage_key`, `file_name`, `file_type`, `file_size`, `content_type`, nullable `uploaded_by_id`, `created_at`. |
| `tasks_bid` | `id`, `task_id`, `technician_id -> accounts_user`, `amount`, `amount_type`, `message`, `duration`, `extra_notes`, `status`, timestamps, `accepted_at`, `rejected_at`. Conditional unique active bid per `(task_id, technician_id)` where status is not `withdrawn`. |
| `tasks_question` | `id`, `task_id`, `asker_id`, `text`, `created_at`, `reply_text`, nullable `replied_by_id`, `replied_at`. There is no reply endpoint implemented. |
| `tasks_service_inquiry` | `id`, contact fields (`name`, `email`, `phone`, `company_name`), `inquiry_type`, `details`, `status`, timestamps. |
| `tasks_milestone` | `id`, `task_id`, `title`, `amount`, `status`, `due_date`, timestamps. It is currently not connected to actual wallet releases. |
| `tasks_task_review` | `id`, `task_id`, `reviewer_id`, `target_user_id`, `rating`, `comment`, `status`, `created_at`. Admin moderation exists; no API creates these reviews. |

### Wallet and transactions

| Table | Columns and relationships |
| --- | --- |
| `wallet_wallet` | `id`, one-to-one `user_id`, `available_balance`, `pending_escrow`, `total_earnings`, `total_withdrawn`, `currency`, timestamps. |
| `wallet_transaction` | `id`, `wallet_id`, `amount`, `type`, `category`, nullable `reference_id -> tasks_task`, `description`, `status`, `metadata` JSON, `created_at`. |

### Messaging

| Table | Columns and relationships |
| --- | --- |
| `messaging_conversation` | `id`, nullable `task_id -> tasks_task`, timestamps, nullable `last_message_at`. |
| `messaging_conversation_participants` | Django M2M join from conversation to users. |
| `messaging_message` | `id`, `conversation_id`, `sender_id`, `text`, attachment URL/key/name/type/size/content type, `created_at`, `read_at`. |

### Companies

| Table | Columns and relationships |
| --- | --- |
| `companies_profile` | `id`, one-to-one `user_id`, identity/contact/location fields (`company_name`, registration number, industry, website, headquarters, country, city, latitude/longitude), JSON services/expertise/hours, logo/cover/about, verification/rating/count fields, analytics counters, currency, notification/privacy/2FA preference flags, timestamps. |
| `companies_project` | `id`, `company_id`, `title`, `status`, `client_name`, `budget`, `timeline`, milestone counters, `payment_status`, `location`, `progress`, timestamps. Separate from `tasks_task`. |
| `companies_service` | `id`, `company_id`, `title`, `category`, `pricing_model`, `status`, `views`, `quotes_count`, `acceptance_rate`, `description`, `images` JSON, `created_at`. |
| `companies_certification` | `id`, `company_id`, `title`, `description`, `created_at`. |
| `companies_review` | `id`, `company_id`, `reviewer_id`, `rating`, `text`, `service`, `created_at`. |
| `companies_team_member` | `id`, `company_id`, nullable `user_id`, `name`, `role`, `email`, `status`, `created_at`. No active API exposes this table. |
| `companies_quote_request` | `id`, `company_id`, client contact, `service`, budget/deadline/location/priority, summaries, `attachments` JSON, `status`, timestamps. |
| `companies_activity` | `id`, `company_id`, `text`, `icon_type`, `created_at`. |

### Governance and support

| Table | Columns and relationships |
| --- | --- |
| `governance_notification` | `id`, `user_id`, `category`, `title`, `body`, `link`, `metadata` JSON, `is_read`, timestamps. In-app only; no push/email dispatcher. |
| `governance_audit_log` | `id`, nullable `actor_id`, `action`, `entity_type`, `entity_id` text, `summary`, `metadata` JSON, nullable `ip_address`, `created_at`. |
| `governance_dispute` | `id`, `task_id`, `opened_by_id`, nullable `against_id`, reason/title/description/status/resolution, nullable `resolution_by_id`, timestamps. |
| `governance_dispute_evidence` | `id`, `dispute_id`, `uploaded_by_id`, URL/key/name/type/content-type/note, `created_at`. |
| `governance_platform_setting` | `id`, unique `key`, `value` JSON, description, `is_sensitive`, nullable `updated_by_id`, timestamps. |
| `governance_cms_page` | `id`, `title`, unique `slug`, `excerpt`, `content`, publication/footer flags, sort order, nullable `updated_by_id`, timestamps. |
| `governance_support_ticket` | `id`, `subject`, `client_id`, `status`, timestamps. |
| `governance_support_message` | `id`, `ticket_id`, `sender_id`, `body`, `created_at`. |

### Django framework tables

The shared database also has Django-managed tables: `django_migrations`, `django_content_type`, `auth_permission`, `auth_group`, `auth_group_permissions`, `accounts_user_groups`, `accounts_user_user_permissions`, `django_admin_log`, and `django_session`. These are backend infrastructure, not mobile product entities.

## Important current limitations and contract risks

* Google login accepts a supplied `ADMIN` role. This is a privilege-escalation vulnerability.
* Any authenticated user can release escrow for any task. The endpoint must be restricted before mobile exposes it.
* Wallet deposits and withdrawals are bookkeeping only; do not present them as real money transfers.
* Any authenticated user can submit a deliverable to any task, and delete upload keys without ownership checks.
* Company profile/project/service routes generally authenticate but do not enforce the company role.
* The admin dashboard/monitoring code uses nonexistent `Task.technician` and lowercase admin/status checks, so it can fail even though the models use `assigned_to` and uppercase `ADMIN`.
* Company quote approval uses nonexistent CompanyProject fields/values and will fail.
* Client listing/search APIs contain unverified-data bypass query parameters intended for admin-like UI use; mobile should not rely on them.
* The API lacks real-time sockets, push notification delivery, email/SMS dispatch, payment-provider webhooks, a review-create endpoint, task-question reply endpoint, and normalized country/city tables.

## Recommended mobile/web parity rules

1. Build one shared API contract/types package for IDs, enum strings, paginated response shapes, timestamps and decimal parsing.
2. Re-fetch task, bid, wallet and conversation state after any mutation. Do not assume a local state transition succeeded until the server returns it.
3. Use `assigned_to`, accepted bid, and `task.status` as the authoritative job state. Do not infer assignment from a notification.
4. Use task `city` as a filter only. Add normalized country/city IDs and optional geospatial coordinates if country/city-first discovery is a product requirement.
5. Avoid exposing wallet deposit/release/payout flows in mobile until payment authorization, idempotency, ownership checks and a provider integration exist.
6. Keep attachments as a two-step process: upload, then send the returned URL/key in the domain object/message.
7. Never implement client-side role checks as security. The backend must enforce every role and ownership rule.

## Prompt for another AI

```text
You are working on Boulot Man, a Next.js + Django REST marketplace. Read BACKEND_ARCHITECTURE_AND_SHARED_SCHEMA.md first. The active backend is backend/config and backend/apps/*; ignore backend/core and top-level backend/accounts because they are legacy/unwired.

Web and mobile share one Django database. Preserve the current schema and API contract unless I explicitly approve a migration. Treat accounts_user.id as the universal identity and tasks_task.assigned_to_id as the canonical task assignee. All money is Decimal/string, timestamps are UTC, and API status strings are case-sensitive.

Marketplace flow: verified client creates/publishes task; verified technician/company bids; client accepts a bid; task becomes in_progress and receives assigned_to; deliverable is submitted; client completes; escrow release is a separate operation. Company projects are a separate data model and must not be confused with marketplace tasks.

Location is currently user-entered text. Existing discovery filters by task city/location, technician country/coverage area, and company headquarters/country. Do not claim IP geolocation exists. If adding location-based discovery, propose normalized country/city data and optional geo coordinates/radius search, with a migration and backward-compatible API.

Before adding UI, inspect the current endpoint and serializer. Use server-returned state, never mock parallel data. Maintain response compatibility for both web and mobile. Do not expose private fields such as document URLs, client contact methods, audit IPs, or wallet ledger data to unauthorized users.

Security work takes priority: remove Google role=ADMIN self-assignment; enforce server-side role/ownership for escrow release, deliverable submission, upload deletion, company routes and conversation creation; add payment idempotency/provider verification before treating wallet actions as payments. Do not fix by adding only frontend checks.

When changing schema, provide: migration, updated serializer/endpoint authorization, contract changes for web/mobile, backfill plan, tests for ownership/status transitions, and an explanation of compatibility risks. Start by summarizing the exact current code path and data tables you will change, then implement only the requested scope.
```
