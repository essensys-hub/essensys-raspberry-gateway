## ADDED Requirements

### Requirement: Single Go process serves all OVH API routes
The consolidated cloud backend SHALL serve identity, admin, legacy IoT, portal, and gateway routes from **one HTTP listener** on the OVH VPS.

#### Scenario: All route prefixes on one port
- **WHEN** Nginx proxies `/api/`, `/api/portal/`, and `/api/gateway/` to the consolidated backend
- **THEN** all three prefixes are handled by the same process without a second backend on `:8081`

### Requirement: Modular bounded contexts
The codebase SHALL organize handlers into packages `identity`, `admin`, `legacyiot`, `portal`, and `gateway` with no business logic duplicated across packages.

#### Scenario: Portal inject does not import OAuth handlers directly
- **WHEN** the portal inject handler enqueues a cloud action
- **THEN** it uses domain/data layers only, not OAuth handler functions from `identity`

### Requirement: Feature flag for incremental rollout
The server SHALL support `CONSOLIDATED_MODE` (default `false` in development until cutover) to enable migrated routes without breaking existing dual-backend deploy.

#### Scenario: Legacy dual deploy unchanged
- **WHEN** `CONSOLIDATED_MODE=false` and only portal module routes are registered
- **THEN** behavior matches pre-consolidation portal-backend

#### Scenario: Consolidated routes enabled
- **WHEN** `CONSOLIDATED_MODE=true`
- **THEN** identity, admin, and legacyiot routes are registered alongside portal and gateway routes
