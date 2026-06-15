## ADDED Requirements

### Requirement: User submits link request before portal access
An authenticated user SHALL submit a link request via `POST /api/portal/link-request` with at minimum `machine_serial` and optional `message`. The request SHALL be stored with status **`pending`**.

#### Scenario: Pending request created
- **WHEN** a logged-in user submits a valid link request
- **THEN** a row exists in `link_requests` with status `pending` and the user's `user_id`

### Requirement: User without approved link cannot control domotics
The portal domotic UI SHALL NOT expose inject controls until the user has an **approved** link request and admin-set `linked_machine_id` / `linked_gateway_id`.

#### Scenario: Pending user sees wait screen
- **WHEN** a user with only a `pending` link request opens `/portal/dashboard`
- **THEN** the UI displays a waiting-for-approval message and no domotic action buttons

#### Scenario: Rejected user sees rejection message
- **WHEN** a user's link request status is `rejected`
- **THEN** the UI displays rejection status and no domotic action buttons

### Requirement: Admin approves link and assigns devices
An admin with role `admin_global` or `support` SHALL approve a link request and assign `linked_machine_id` and `linked_gateway_id` via existing admin APIs (`PUT /api/admin/users/{id}/links`) plus updating the link request to **`approved`**.

#### Scenario: Admin approval enables portal
- **WHEN** admin approves the link request and sets machine and gateway IDs on the user
- **THEN** the user can access domotic controls on the next portal session

### Requirement: Self-service IP-based linking is not used for remote portal
The remote portal workflow SHALL NOT rely on `PUT /api/profile/links` IP-match self-linking for distant users.

#### Scenario: Remote user cannot self-link by IP
- **WHEN** a remote user attempts profile self-link from a different public IP than the gateway
- **THEN** the system rejects self-link and directs the user to submit an admin link request instead
