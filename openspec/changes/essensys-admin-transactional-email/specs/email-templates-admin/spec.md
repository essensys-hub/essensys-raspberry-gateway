## ADDED Requirements

### Requirement: Admin CRUD for email templates
The backend SHALL expose routes under `/api/admin/email-templates` protected by `AdminAuth` and restricted to `admin_global` for write operations.

| Method | Path | Action |
|--------|------|--------|
| GET | `/api/admin/email-templates` | List all templates |
| GET | `/api/admin/email-templates/{slug}` | Get one template |
| PUT | `/api/admin/email-templates/{slug}` | Create or update template |
| POST | `/api/admin/email-templates/{slug}/preview` | Render preview with sample or provided data |
| POST | `/api/admin/email-templates/test` | Send test email to requesting admin |

#### Scenario: List templates
- **WHEN** `admin_global` requests `GET /api/admin/email-templates`
- **THEN** the response includes all slugs with subject, `enabled`, and `auto_send` flags

#### Scenario: Update template body
- **WHEN** `admin_global` sends `PUT /api/admin/email-templates/user_welcome` with new subject and body
- **THEN** the template is persisted and returned with updated `updated_at`

### Requirement: Template schema
Each template row SHALL include: `slug` (unique), `name`, `subject`, `body_html`, `body_text`, `enabled` (bool), `auto_send` (bool), `created_at`, `updated_at`.

#### Scenario: Disable template
- **WHEN** `enabled` is set to `false`
- **THEN** auto-send hooks and resend using that slug return HTTP 400 or skip with clear message

### Requirement: Default templates seeded on migration
Migration `006_email_templates.sql` SHALL seed disabled default templates for slugs: `user_welcome`, `device_allocation`, `password_reset`, `role_updated`.

#### Scenario: Fresh database migration
- **WHEN** migration runs on an empty database
- **THEN** four template rows exist with French placeholder content and `enabled=false`, `auto_send=false`

### Requirement: Documented template variables
Admin API documentation SHALL list allowed placeholders: `first_name`, `last_name`, `email`, `role`, `portal_url`, `temporary_password`, `gateway_name`, `gateway_ip`, `armoire_label`, `armoire_ip`, `support_email`.

#### Scenario: Preview with sample data
- **WHEN** admin posts to preview endpoint without custom payload
- **THEN** the response shows rendered subject and body using built-in sample values
