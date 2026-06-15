## ADDED Requirements

### Requirement: OAuth and email auth routes preserved
The consolidated backend SHALL expose the same auth routes as `essensys-support-site/backend`: register, login, logout, Google OAuth, Apple OAuth, and admin login (deprecated).

#### Scenario: Email login returns JWT
- **WHEN** a user posts valid credentials to `POST /api/auth/login`
- **THEN** the response includes a JWT and user object with the same shape as the support-site backend

#### Scenario: Google OAuth redirect unchanged
- **WHEN** a browser requests `GET /api/auth/google/login`
- **THEN** the user is redirected to Google OAuth with the same callback URL path `/api/auth/google/callback`

### Requirement: JWT emit and validate in same binary
The consolidated backend SHALL sign JWTs in the identity module and validate them in portal/admin middleware using the same `JWT_SECRET`.

#### Scenario: Portal accepts JWT from consolidated login
- **WHEN** a user logs in via consolidated backend and calls `POST /api/portal/inject` with the returned JWT
- **THEN** the request is authenticated without calling an external auth service

### Requirement: Profile routes preserved
Routes `GET/PUT/DELETE /api/profile`, `GET /api/profile/export`, `PUT /api/profile/links`, and `GET /api/devices/nearby` SHALL remain available with identical paths and authorization rules.

#### Scenario: Profile read after OAuth login
- **WHEN** an authenticated user requests `GET /api/profile`
- **THEN** the response includes email, role, and linked device fields from PostgreSQL `users`
