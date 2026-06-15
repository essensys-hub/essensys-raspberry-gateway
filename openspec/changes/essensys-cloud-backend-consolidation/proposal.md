## Why

The OVH VPS at `https://mon.essensys.fr` runs **two separate Go backends** (`essensys-support-site/backend` on `:8080` and `essensys-user-portal-backend` on `:8081`) sharing PostgreSQL and JWT secrets. This split causes duplicated gateway eligibility rules, fragmented observability, dual systemd services, and a broken remote UX: `GET /api/portal/exchange` returns an empty stub so `essensys-user-portal-frontend` cannot show shutter/light state. Legacy armoires on CM5 gateways already work for **commands** via cloudsync but need a **unified cloud hub** and real exchange data to complete the remote experience.

## What Changes

- **Modular consolidation** into `essensys-user-portal-backend` as the single OVH API process: packages `identity`, `admin`, `legacyiot`, `portal`, `gateway`.
- **Migrate** auth (OAuth, register/login, JWT emit), admin, newsletter, and passive IoT routes (`/mystatus`, `/serverinfos`, `/myactions`, `/api/infos`) from `essensys-support-site/backend` with **stable HTTP paths**.
- **Unify** gateway eligibility (`essensys-server` ineligible for remote portal) in one domain module; remove `gatewayrules` duplication.
- **Implement** real domotic state for the portal: gateway push `POST /api/gateway/exchange` + `GET /api/portal/exchange` reading PG cache (Option A + B fallback per design).
- **PostgreSQL migration** for machine inventory (replace `machines.json` MemoryStore).
- **Ansible**: single backend role, one systemd unit, Nginx single upstream `/api/`.
- **Deprecate** `essensys-support-site/backend/`; support-site repo keeps React frontend only.
- **Non-goals**: merge frontends, expose Redis/MQTT on WAN, support `essensys-server` on remote portal, change BP_MQX_ETH firmware poll path.

## Capabilities

### New Capabilities

- `cloud-backend-architecture`: Single modular Go hub on OVH; bounded contexts; one HTTP port behind Nginx.
- `identity-module-migration`: OAuth, register/login, JWT, profile routes from support-site backend.
- `admin-module-migration`: Admin stats, users, newsletter, audit routes preserved.
- `legacy-iot-module`: Passive WAN IoT routes with Basic Auth compatibility.
- `machines-pg-migration`: Replace `machines.json` with PostgreSQL tables.
- `gateway-rules-unified`: Single `IsRemoteEligibleGateway()` source of truth.
- `portal-exchange-sync`: Portal reads real exchange state from OVH cache.
- `gateway-exchange-push`: Gateway cloudsync pushes Redis snapshot to OVH.
- `ansible-single-backend-deploy`: Merged Ansible role, systemd, `.env`, Nginx upstream.
- `support-site-backend-deprecation`: Removal plan and documentation for old backend binary.
- `legacy-armoire-portal-e2e`: End-to-end validation CM5 + user-portal-frontend + passive IoT.

### Modified Capabilities

- `portal-user-auth`: JWT may be **issued and validated** by the same consolidated backend (no cross-binary secret coupling).
- `cloud-action-queue`: Unchanged contract; runs in consolidated `portal` module.
- `gateway-https-agent`: Extended with optional exchange push on heartbeat interval.

## Impact

- **Primary repo**: `essensys-user-portal-backend` (major refactor + new modules).
- **Deprecated repo path**: `essensys-support-site/backend/` (removed after migration).
- **Modified repos**: `essensys-server-backend` (cloudsync exchange push), `essensys-ansible` (single backend role), `essensys-support-site` (nginx, frontend only), `essensys-user-portal-frontend` (exchange UI behavior).
- **APIs**: All existing paths preserved; new `POST /api/gateway/exchange`; `/api/portal/exchange` returns data.
- **Database**: New tables `machines`, `machine_telemetry`, `gateway_push_status`, `gateway_exchange_cache`.
- **Dependencies**: Consolidated `go.mod` (chi, jwt, oauth2, gomail, sqlx, newrelic).
- **Risk**: Regression on legacy Basic Auth IoT or OAuth — mitigated by route-parity tests and phased cutover with rollback flag.
