## ADDED Requirements

### Requirement: Single gateway eligibility function
Gateway remote portal eligibility SHALL be determined by exactly one function `IsRemoteEligibleGateway()` in `internal/domain/gateway.go`.

#### Scenario: essensys-server ineligible
- **WHEN** `IsRemoteEligibleGateway` is called with gateway ID `essensys-server` or `gw-essensys-server`
- **THEN** it returns `false`

#### Scenario: CM5 gateway eligible
- **WHEN** `IsRemoteEligibleGateway` is called with gateway ID `gw-essensys-gateway` or similar CM5 hostname
- **THEN** it returns `true`

### Requirement: No duplicate gatewayrules package
The `essensys-support-site/backend/internal/gatewayrules/` package SHALL be removed or deprecated after consolidation; all callers use `internal/domain/gateway.go`.

#### Scenario: Admin link validation uses unified rule
- **WHEN** admin assigns `linked_gateway_id` for a user with remote portal access
- **THEN** the same eligibility check is applied as portal link-request status

#### Scenario: LinkGate UI consistent with backend
- **WHEN** a user has `linked_gateway_id` pointing to `essensys-server`
- **THEN** `portal_access` is false and LinkGate shows remote portal unavailable
