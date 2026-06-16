## ADDED Requirements

### Requirement: Transactional email uses SMTP environment
The backend SHALL send transactional emails using `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, and `SMTP_FROM` when all required variables are set.

#### Scenario: SMTP fully configured
- **WHEN** all `SMTP_*` variables are set and a transactional send is requested
- **THEN** the mailer attempts delivery via TLS/SSL on the configured port

#### Scenario: SMTP missing
- **WHEN** a transactional send is requested and `SMTP_HOST` is empty
- **THEN** the API returns HTTP 503 with a clear error message and no silent failure

### Requirement: Shared mailer for newsletter and transactional
The backend SHALL expose a single mail-sending function in `internal/notify` used by both newsletter sends and transactional sends.

#### Scenario: Newsletter still works after refactor
- **WHEN** an admin sends a newsletter draft via `POST /api/admin/newsletters/{id}/send`
- **THEN** delivery uses the same SMTP configuration as transactional email

### Requirement: Template rendering with allowlisted variables
The mailer SHALL replace only documented placeholders in subject and body fields.

#### Scenario: Welcome template render
- **WHEN** template `user_welcome` contains `Bonjour {{first_name}}, connectez-vous sur {{portal_url}}`
- **THEN** the rendered email substitutes the user's first name and the `FRONTEND_URL` environment value

#### Scenario: Unknown placeholder
- **WHEN** a template contains `{{unknown_key}}`
- **THEN** the placeholder is left empty or replaced with an empty string without panicking

### Requirement: Send attempts are logged
Each send attempt SHALL create a row in `email_send_log` with recipient, template slug, status, optional error message, and initiating admin id when applicable.

#### Scenario: Successful send
- **WHEN** SMTP delivery succeeds
- **THEN** `email_send_log.status` is `sent` and an audit entry `EMAIL_SENT` is created

#### Scenario: Failed SMTP
- **WHEN** SMTP dial or send fails
- **THEN** `email_send_log.status` is `failed`, error message is stored, and audit entry `EMAIL_SEND_FAILED` is created

### Requirement: Sensitive content is not logged
The backend SHALL NOT write full email bodies or plaintext passwords to application logs or audit detail fields.

#### Scenario: Welcome email with password
- **WHEN** a welcome email is sent including `temporary_password`
- **THEN** logs and audit contain template slug and recipient only
