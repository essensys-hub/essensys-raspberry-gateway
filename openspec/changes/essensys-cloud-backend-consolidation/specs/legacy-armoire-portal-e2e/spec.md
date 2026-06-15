## ADDED Requirements

### Requirement: End-to-end remote domotic path on CM5
A documented E2E test SHALL verify the full path: OAuth login → link request → admin approval → portal inject → cloudsync → Redis → BP_MQX_ETH → exchange UI update.

#### Scenario: Shutter command from portal moves physical output
- **WHEN** an approved user on `essensys-user-portal-frontend` sends a shutter inject for index 613
- **THEN** within 60 seconds the shutter actuates on the CM5-connected armoire and exchange reflects the new state within 30 seconds

### Requirement: Passive WAN machine monitoring preserved
E2E SHALL verify a legacy WAN machine can still POST `/api/mystatus` and appear in admin machines list after consolidation.

#### Scenario: MyStatus visible in admin
- **WHEN** a test machine posts mystatus to consolidated backend with Basic Auth
- **THEN** admin `GET /api/admin/machines` includes the machine with updated last_seen

### Requirement: essensys-server blocked from remote portal
E2E SHALL confirm users linked to `essensys-server` gateway cannot obtain `portal_access: true`.

#### Scenario: LinkGate blocks essensys-server
- **WHEN** a user has `linked_gateway_id` normalized to `essensys-server`
- **THEN** `GET /api/portal/link-request/status` returns `portal_access: false` and LinkGate UI shows unavailable message

### Requirement: Gateway offline behavior
E2E SHALL verify portal exchange and gateway status when CM5 cloudsync is stopped.

#### Scenario: Offline gateway status
- **WHEN** cloudsync is disabled for more than 2 minutes
- **THEN** `GET /api/portal/gateway/status` reports offline and exchange shows stale or empty with user-visible warning

### Requirement: E2E documentation artifact
A markdown runbook `docs/cloud-backend-consolidation-e2e.md` SHALL list prerequisites, test accounts, CM5 lab setup, and pass/fail checklist.

#### Scenario: Runbook enables repeat validation
- **WHEN** a new operator follows the E2E runbook on a lab CM5
- **THEN** they can execute all scenarios without undocumented steps
