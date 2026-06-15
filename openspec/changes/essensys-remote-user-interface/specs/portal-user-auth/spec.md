## ADDED Requirements

### Requirement: Portal validates support-site JWT
The user-portal-backend SHALL validate JWT bearer tokens issued by `essensys-support-site` using the shared `JWT_SECRET`. Unauthenticated requests to `/api/portal/*` SHALL receive HTTP 401.

#### Scenario: Valid JWT accepted
- **WHEN** a request includes a valid support-site JWT in `Authorization: Bearer`
- **THEN** portal-backend resolves the user identity and proceeds to authorization checks

#### Scenario: Missing JWT rejected
- **WHEN** a request to `/api/portal/inject` has no Authorization header
- **THEN** the response status is 401

### Requirement: Portal inject requires approved link
`POST /api/portal/inject` SHALL succeed only if the authenticated user has `linked_machine_id` set and an associated link request in **`approved`** status.

#### Scenario: Unlinked user inject forbidden
- **WHEN** an authenticated user without approved link posts to `/api/portal/inject`
- **THEN** the response status is 403 with a clear error code indicating link not approved

### Requirement: CORS restricted to mon.essensys.fr
The portal-backend SHALL allow browser CORS only from origin **`https://mon.essensys.fr`**.

#### Scenario: Foreign origin blocked
- **WHEN** a browser preflight originates from `https://evil.example.com`
- **THEN** CORS headers do not allow the request
