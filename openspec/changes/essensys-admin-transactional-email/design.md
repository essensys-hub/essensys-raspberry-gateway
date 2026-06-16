## Context

- Admin SPA: `essensys-support-site/site` → `/admin` tabs (`Admin.jsx`: dashboard, newsletters, users, catalog, audit).
- User list UI: `UserManager.jsx` — columns Gateway, Serveur, Armoire, Actions (« Lier Appareils »).
- API: consolidated `essensys-user-portal-backend` (`CONSOLIDATED_MODE=true`) on `:8080` via Nginx.
- SMTP production: `essensys-ansible/group_vars/essensys/vault.yml` (`vault_smtp_*`) → `roles/cloud_backend/templates/cloud-backend.env.j2` → `SMTP_*`.
- Newsletter tables exist (`005_newsletter.sql`); transactional templates are **separate** from marketing newsletters.

## Goals / Non-Goals

**Goals:**

- Admins define and edit email templates without redeploying the backend.
- New users can receive welcome email when `user_welcome.auto_send=true`.
- Admins can resend account or allocation info from the user list.
- Send failures are logged (audit + `email_send_log`) and visible in admin UI.

**Non-Goals (MVP):**

- SMS notifications.
- Multi-language template variants.
- Rich HTML WYSIWYG editor.
- End-user notification preference center.
- Full `forgot-password` self-service flow (phase 2).

## Decisions

### 1. Templates in PostgreSQL

**Chosen**: table `email_templates` with `slug`, `subject`, `body_html`, `body_text`, `auto_send`, `enabled`, `updated_at`.

**Rationale**: editable by admins; version field reserved for future history.

**Alternative**: file-based templates in repo — rejected (requires deploy for copy changes).

### 2. Simple `{{variable}}` rendering with allowlist

**Chosen**: Go `text/template` or controlled replace with documented keys only.

**Rationale**: prevents injection; matches admin-editable copy.

### 3. Shared mailer package

**Chosen**: `internal/notify/mailer.go` — extract `sendEmail` from `newsletter.go`; newsletter and transactional both call it.

### 4. Resend API

**Chosen**: `POST /api/admin/users/{id}/resend-email` body `{ "template_slug": "user_welcome", "password": "optional" }`.

**Security**: `admin_global` required; audit log mandatory; rate-limit per user (e.g. 5/hour) in phase 2.

### 5. Welcome password handling

**Chosen**: send plaintext password **only** at create time (from request body) or when admin provides it in resend modal.

**Rationale**: bcrypt hash is not reversible; template must not imply password recovery from DB.

### 6. UI placement

**Chosen**: new tab `email-templates` in `Admin.jsx`; button « Renvoyer email » in `UserManager.jsx` Actions column.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| SMTP misconfigured on VPS | `GET /api/admin/email/health` + admin banner |
| PII in application logs | Log template slug + recipient + status only |
| Email spam on bulk resend | Admin-only; optional rate limit |
| Duplicate sends on retry | Idempotency key per (user_id, template_slug, day) optional phase 2 |

## Migration Plan

1. Deploy migration `006_email_templates.sql` (seed disabled defaults).
2. Deploy backend with mailer + routes (auto_send off by default).
3. Deploy admin UI (templates tab + resend button).
4. Operator edits templates in admin, enables `user_welcome.auto_send`.
5. Verify with test user creation on staging/prod.

**Rollback**: set all `auto_send=false`; disable resend routes via feature flag `TRANSACTIONAL_EMAIL_ENABLED=false` if needed.

## Open Questions

- Should `admin_local` be allowed to resend emails for users on their machine only?
- Include Essensys branding HTML wrapper or plain text MVP only?
