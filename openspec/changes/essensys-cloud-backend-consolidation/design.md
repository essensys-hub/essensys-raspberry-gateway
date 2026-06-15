## Context

Essensys operates `https://mon.essensys.fr` on an OVH VPS with:

- **`essensys-support-site`**: React SPA + Go backend `:8080` — identity (OAuth Google/Apple, email), admin, newsletter, passive IoT monitoring (`POST /api/mystatus`, `GET /api/serverinfos`), gateway push status (`POST /api/infos`), `machines.json` file store.
- **`essensys-user-portal-backend`**: Go BFF `:8081` — link requests, cloud action queue, gateway HTTPS poll API, inject with 590+605..622 expansion, New Relic APM.
- **`essensys-user-portal-frontend`**: SPA `/portal/*` — remote domotic UI; calls `/api/portal/inject` (works) and `/api/portal/exchange` (stub returns `[]`).
- **`essensys-raspberry-gateway` + `essensys-server-backend`**: CM5 edge — cloudsync polls OVH, applies to local Redis; BP_MQX_ETH polls HTTP on eth1.

Change `essensys-remote-user-interface` delivered the remote portal MVP. This change **consolidates backends** and **closes the exchange gap** without altering firmware or LAN HTTP:80 semantics.

Prompt source: `prompts/CloudBackendConsolidation.md`.

## Goals / Non-Goals

**Goals:**

- One Go process serves `/api/*`, `/api/portal/*`, `/api/gateway/*` on OVH.
- Modular packages: `identity`, `admin`, `legacyiot`, `portal`, `gateway`, `domain`, `data`, `middleware`.
- HTTP route paths and Basic Auth legacy behavior unchanged for WAN machines.
- OAuth and JWT emit/validate in consolidated backend; portail frontend unchanged.
- Real `/api/portal/exchange` data for CM5-linked users.
- Single Ansible deploy + systemd unit + Nginx upstream.
- Remove duplicate `gatewayrules` in support-site.

**Non-Goals:**

- Merge `essensys-support-site/site` and `essensys-user-portal-frontend`.
- Remote portal for `essensys-server` installs (remain blocked).
- Redis/MQTT on OVH WAN.
- Change BP_MQX_ETH local poll path or cloud action normalization rules.
- Rename repo to `essensys-cloud-backend` in MVP (optional follow-up).

## Decisions

### 1. Consolidation target: `essensys-user-portal-backend`

**Chosen**: Extend `essensys-user-portal-backend` with migrated modules rather than moving portal code into support-site.

**Rationale**: Portal is the active BFF for domotic commands; support-site backend is passive monitoring + auth. Portal repo already has migrations, gateway API, New Relic, and cleaner structure.

**Alternative**: Monolith in support-site — rejected (wrong bounded context ownership).

### 2. Single HTTP port: `:8080`

**Chosen**: Consolidated service listens on **`:8080`** (reuse support-site port); retire `:8081` after cutover.

**Rationale**: Nginx already proxies most `/api/` to `:8080`; minimizes nginx diff. Portal paths move to same upstream.

**Alternative**: Keep `:8081` — rejected (perpetuates dual-service ops).

### 3. Package layout

```text
internal/
  identity/     # auth, oauth, profile
  admin/        # admin handlers, newsletter
  legacyiot/    # mystatus, serverinfos, myactions, infos
  portal/       # link-request, inject, exchange (from handlers_portal)
  gateway/      # poll, done, heartbeat, exchange push
  domain/       # gateway eligibility, order expansion, user models
  data/         # stores + migrations
  middleware/   # JWT, Basic Auth legacy, rate limit, NR
```

Router in `internal/api/router.go` mounts sub-routers per module.

### 4. Exchange state: Option A (push) + Option B (fallback)

**Chosen**:

1. **Primary**: Gateway cloudsync pushes exchange snapshot via `POST /api/gateway/exchange` every heartbeat (60s) or on Redis change (debounce 5s).
2. **Storage**: Table `gateway_exchange_cache` keyed by `machine_id`.
3. **Portal read**: `GET /api/portal/exchange?keys=` reads cache for user's `linked_machine_id`.
4. **Fallback**: If cache stale (>120s) or empty, optionally serve last `machine_telemetry` from `POST /api/mystatus` (stale indicator in response metadata).

**Alternatives**:

- Poll proxy from OVH to gateway — rejected (inbound to customer LAN).
- Redis on OVH — rejected (firmware/LAN requirement).

### 5. Machine store: PostgreSQL phased

**Phase 1**: Migrate handlers with optional in-memory adapter behind interface.  
**Phase 2**: SQL migrations for `machines`, `machine_telemetry`, `gateway_push_status`; import script from `machines.json`.

### 6. Gateway eligibility: single module

**Chosen**: Keep `internal/domain/gateway.go` (`RemoteIneligibleGatewayHost = "essensys-server"`). Delete `essensys-support-site/backend/internal/gatewayrules/`. Admin and portal import same function.

### 7. Auth: emit + validate in one binary

**Chosen**: JWT signed in `identity` module with same claims (`sub`, `role`, `iss`). Portal middleware validates without HTTP call to external service.

**Migration**: `JWT_SECRET` unchanged; tokens issued before cutover remain valid if secret unchanged.

### 8. Ansible cutover

**Chosen**: New variable `cloud_backend_consolidated: true` switches role to build unified binary; `cloud_backend_legacy_mode: true` rollback restores old dual services.

**Blue/green**: Deploy consolidated service on `:8080`; verify; stop `essensys-portal-backend` on `:8081`; update Nginx to remove `:8081` upstream.

### 9. Support-site backend deprecation

**Chosen**: After prod validation, remove `backend/` from `essensys-support-site` repo; update README; archive tag `support-backend-last`.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| OAuth redirect URLs break | Keep same `/api/auth/*` paths; test Google/Apple callbacks on staging |
| Legacy Basic Auth machines stop reporting | Route-parity integration tests; canary deploy |
| Exchange cache stale misleads UI | Return `stale: true` + timestamp; UI shows warning |
| Large go.mod merge conflicts | Module-by-module PRs per phase |
| Downtime during cutover | Maintenance page exists; deploy off-peak |
| Newsletter JSON vs PG | Phase 1 keep JSON file; phase 2 migrate |

## Migration Plan

1. **Phase 0**: OpenSpec approved; scaffold packages; feature flag `CONSOLIDATED_MODE=false`.
2. **Phase 1**: Mount identity + admin routes behind flag; parallel testing on `:8082` staging port.
3. **Phase 2**: Migrate legacyiot; PG tables; import machines.json.
4. **Phase 3**: Exchange push + portal read; cloudsync update on CM5.
5. **Phase 4**: Ansible single service; Nginx cutover; stop old `:8081` service.
6. **Phase 5**: Remove support-site/backend; documentation update.
7. **Rollback**: `cloud_backend_legacy_mode: true` + redeploy previous Ansible revision.

## Open Questions

- Rename repo to `essensys-cloud-backend` after consolidation? (Defer to post-MVP.)
- Newsletter PostgreSQL migration in same change or follow-up? (Recommend follow-up if JSON works.)
- Deprecate `POST /api/admin/login` static token? (Mark deprecated in phase 3; remove phase 5.)
