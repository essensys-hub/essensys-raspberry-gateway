## ADDED Requirements

### Requirement: Admin routes preserved
All admin routes under `/api/admin/*` and newsletter routes SHALL remain available with the same HTTP methods and role checks (`admin_global`, `admin_local`, `support`).

#### Scenario: Admin stats accessible
- **WHEN** an admin JWT requests `GET /api/admin/stats`
- **THEN** the response includes machine and gateway counts consistent with the data store

#### Scenario: User link assignment
- **WHEN** an admin posts to `PUT /api/admin/users/{id}/links` with `linked_machine_id` and `linked_gateway_id`
- **THEN** the user's PostgreSQL row is updated and audit log entry is created

### Requirement: Newsletter subscribe and admin CRUD
Public `POST /api/newsletter/subscribe` and admin newsletter CRUD routes SHALL function as before consolidation.

#### Scenario: Newsletter subscribe
- **WHEN** a visitor posts an email to `POST /api/newsletter/subscribe`
- **THEN** the subscriber is stored and HTTP 200 or 201 is returned

### Requirement: Audit log preserved
Admin audit queries via `GET /api/admin/audit` SHALL return entries filtered by admin role scope as in the support-site backend.

#### Scenario: Global admin sees all audit entries
- **WHEN** `admin_global` requests audit logs with pagination
- **THEN** entries from all users are returned up to the requested limit
