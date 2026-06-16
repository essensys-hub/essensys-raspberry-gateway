## Why

Admins create users and assign gateways/armoires via the support-site admin (`UserManager`), but **no transactional email** is sent (welcome credentials, allocation summary, password reset). Operators must manually communicate access details. SMTP is configured for **newsletter only** (`internal/admin/newsletter.go`), causing support friction and user confusion when accounts are created without notification.

## What Changes

- **Transactional email engine** in `essensys-user-portal-backend`: reusable mailer built on existing `SMTP_*` / gomail, separate from newsletter drafts.
- **Email templates** stored in PostgreSQL, editable in admin UI: types `user_welcome`, `device_allocation`, `password_reset`, `role_updated` (extensible).
- **Template variables** (`{{first_name}}`, `{{email}}`, `{{portal_url}}`, `{{gateway_name}}`, `{{gateway_ip}}`, `{{armoire_label}}`, `{{temporary_password}}`, etc.).
- **Auto-send hooks**: optional send on `CreateUser`, `UpdateUserLinks` when template `auto_send=true`.
- **Resend button** per user row: « Renvoyer email » (welcome or allocation template).
- **Admin section** new tab « Modèles email » in `essensys-support-site/site/src/pages/Admin.jsx`.
- **Audit log** entries for every send / resend / failure.
- **SMTP health**: admin-visible status + test send endpoint.

## Capabilities

### New Capabilities

- `transactional-email-engine`: send, render templates, SMTP errors, audit.
- `email-templates-admin`: CRUD templates, preview, enable/disable auto-send per type.
- `user-lifecycle-notifications`: hooks on user create, link update, password reset (phase 2).
- `admin-ui-email-actions`: resend button, templates editor, test email.

### Modified Capabilities

- `admin-module-migration`: extend admin routes with `/api/admin/email-templates/*`, `/api/admin/email/health`, and `/api/admin/users/{id}/resend-email`.

## Impact

- **Modified repos**: `essensys-user-portal-backend` (primary), `essensys-support-site/site` (admin UI), docs.
- **Ansible**: no new secrets — reuse `vault_smtp_*` in `cloud-backend.env.j2`.
- **DB**: migration `006_email_templates.sql` + `email_send_log` table.
- **Non-goals (MVP)**: SMS, multi-language templates, HTML WYSIWYG builder, user-facing notification preferences.
