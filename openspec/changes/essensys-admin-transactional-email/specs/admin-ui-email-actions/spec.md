## ADDED Requirements

### Requirement: Email templates admin tab
`Admin.jsx` SHALL add a tab `email-templates` (label « Modèles email ») visible to users with role `admin_global`.

#### Scenario: Navigate to templates
- **WHEN** `admin_global` opens `/admin` and selects the email templates tab
- **THEN** a list of template slugs with edit actions is displayed

#### Scenario: Non-global admin denied
- **WHEN** a user without `admin_global` attempts to open the templates tab
- **THEN** the tab is hidden or shows an access denied message

### Requirement: Template editor UI
The templates page SHALL allow editing subject, body (HTML and/or plain text), `enabled`, and `auto_send` per template, with save calling `PUT /api/admin/email-templates/{slug}`.

#### Scenario: Save template changes
- **WHEN** admin edits the welcome template and clicks save
- **THEN** changes persist and a success confirmation is shown

#### Scenario: Preview template
- **WHEN** admin clicks preview
- **THEN** rendered subject and body are shown using the preview API

#### Scenario: Test send
- **WHEN** admin clicks « Envoyer un test »
- **THEN** `POST /api/admin/email-templates/test` is called and result is displayed

### Requirement: Resend button on user list
`UserManager.jsx` Actions column SHALL include a « Renvoyer email » control per user row.

#### Scenario: Open resend modal
- **WHEN** admin clicks « Renvoyer email » on a user row
- **THEN** a modal allows selecting template (`user_welcome`, `device_allocation`) and optional password for welcome

#### Scenario: Successful resend
- **WHEN** admin confirms resend
- **THEN** `POST /api/admin/users/{id}/resend-email` is called and a success toast or alert is shown

#### Scenario: Resend failure
- **WHEN** API returns SMTP error
- **THEN** UI displays the error message without clearing the user list

### Requirement: SMTP status visible in admin
The admin UI SHALL call `GET /api/admin/email/health` and display a warning banner when transactional email is not configured.

#### Scenario: SMTP not configured
- **WHEN** health endpoint reports `configured: false`
- **THEN** a banner states that transactional emails are disabled and points operators to `vault_smtp_*` / Ansible deployment docs

#### Scenario: SMTP configured
- **WHEN** health endpoint reports `configured: true`
- **THEN** no warning banner is shown on the email templates tab
