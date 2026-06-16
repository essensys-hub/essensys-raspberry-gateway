## 1. Backend — mailer + database

- [ ] 1.1 Extract `internal/notify/mailer.go` from newsletter `sendEmail`
- [ ] 1.2 Add migration `006_email_templates.sql` (`email_templates`, `email_send_log`)
- [ ] 1.3 Implement `EmailTemplateStore` CRUD in `internal/data/`
- [ ] 1.4 Template renderer with allowlisted variables
- [ ] 1.5 Seed default templates (`user_welcome`, `device_allocation`, `password_reset`, `role_updated`) — disabled by default
- [ ] 1.6 Register routes in `internal/admin/routes.go`
- [ ] 1.7 `GET /api/admin/email/health`
- [ ] 1.8 `GET|PUT /api/admin/email-templates` and `/{slug}`
- [ ] 1.9 `POST /api/admin/email-templates/{slug}/preview`
- [ ] 1.10 `POST /api/admin/email-templates/test`
- [ ] 1.11 Unit tests: render, SMTP missing, disabled template

## 2. Backend — lifecycle hooks

- [ ] 2.1 Hook `CreateUser` → send `user_welcome` when `enabled` + `auto_send`
- [ ] 2.2 Hook `UpdateUserLinks` → send `device_allocation` when `enabled` + `auto_send`
- [ ] 2.3 `POST /api/admin/users/{id}/resend-email`
- [ ] 2.4 Audit log: `EMAIL_SENT`, `EMAIL_SEND_FAILED`
- [ ] 2.5 Write rows to `email_send_log` on every attempt
- [ ] 2.6 Integration test with mock SMTP or env guard

## 3. Admin UI — `essensys-support-site/site`

- [ ] 3.1 Add tab `email-templates` in `Admin.jsx`
- [ ] 3.2 Create `EmailTemplates.jsx` (list, edit subject/body, auto_send toggle, preview, test send)
- [ ] 3.3 Add « Renvoyer email » button + modal in `UserManager.jsx`
- [ ] 3.4 SMTP health banner when `/api/admin/email/health` reports misconfiguration
- [ ] 3.5 French labels consistent with existing admin UI
- [ ] 3.6 Build smoke test on `/admin`

## 4. Ops and documentation

- [ ] 4.1 Verify `vault_smtp_*` on VPS (`/opt/essensys/cloud-backend/.env`)
- [ ] 4.2 Update `essensys-user-portal-backend/docs/deployment.md` (transactional vs newsletter)
- [ ] 4.3 Update `essensys-support-site/docs/configuration.md` if needed
- [ ] 4.4 Enable `user_welcome.auto_send` after operator validates template copy

## 5. Phase 2 (post-MVP)

- [ ] 5.1 `POST /api/auth/forgot-password` with `password_reset` template
- [ ] 5.2 `role_updated` auto-send on `PUT /api/admin/users/{id}/role`
- [ ] 5.3 Rate limiting on resend endpoint
- [ ] 5.4 HTML wrapper / Essensys branding
