## ADDED Requirements

### Requirement: Optional auto-send on user creation
When `POST /api/admin/users` succeeds and template `user_welcome` has `enabled=true` and `auto_send=true`, the backend SHALL send the welcome email using the plaintext password from the request body.

#### Scenario: Welcome auto-send enabled
- **WHEN** admin creates a user and `user_welcome` has `auto_send=true`
- **THEN** the user receives a welcome email and audit logs `EMAIL_SENT` with slug `user_welcome`

#### Scenario: Welcome auto-send disabled
- **WHEN** `user_welcome.auto_send` is `false`
- **THEN** the user is created without email; admin may trigger resend later

#### Scenario: Create succeeds even if email fails
- **WHEN** user creation succeeds but SMTP send fails
- **THEN** HTTP 201 or 200 is still returned for user creation, email failure is logged, and response may include `email_sent: false`

### Requirement: Optional auto-send on device allocation
When `PUT /api/admin/users/{id}/links` updates `linked_gateway_id` or `linked_armoire_id` and template `device_allocation` has `enabled=true` and `auto_send=true`, the backend SHALL send an allocation summary email.

#### Scenario: Link gateway and armoire
- **WHEN** admin saves links for a user with gateway hostname and armoire machine resolved
- **THEN** the email includes gateway name/IP and armoire label/IP in rendered template variables

#### Scenario: Allocation template disabled
- **WHEN** `device_allocation.enabled` is `false`
- **THEN** link update completes without sending email

### Requirement: Resend email for existing user
The backend SHALL expose `POST /api/admin/users/{id}/resend-email` accepting `{ "template_slug": string, "password": string optional }`.

#### Scenario: Resend welcome with password
- **WHEN** admin resends `user_welcome` with `password` in body
- **THEN** email is sent with `{{temporary_password}}` substituted and attempt is logged

#### Scenario: Resend welcome without password
- **WHEN** admin resends `user_welcome` without password and template contains `{{temporary_password}}`
- **THEN** placeholder is replaced with a French fallback such as « contactez votre administrateur » or API returns HTTP 400 requiring password

#### Scenario: Resend allocation template
- **WHEN** admin resends `device_allocation` for a user with linked devices
- **THEN** current gateway and armoire data are resolved and included in the email

### Requirement: Password reset email deferred to phase 2
`POST /api/auth/forgot-password` is out of MVP scope; template `password_reset` SHALL be seeded but not wired until phase 2.

#### Scenario: Forgot password not implemented in MVP
- **WHEN** client calls `POST /api/auth/forgot-password` before phase 2
- **THEN** endpoint may return HTTP 501 or remain unregistered; documented in tasks phase 2
