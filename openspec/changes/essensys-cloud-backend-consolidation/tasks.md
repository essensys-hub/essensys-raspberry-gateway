## 1. Phase 0 — OpenSpec et scaffold

- [x] 1.1 Review and approve change `essensys-cloud-backend-consolidation` (proposal, design, specs)
- [x] 1.2 Create package scaffold in `essensys-user-portal-backend`: `internal/identity`, `admin`, `legacyiot`, `portal`, `gateway`
- [x] 1.3 Add feature flag `CONSOLIDATED_MODE` (default `false`) in `cmd/server/main.go`
- [x] 1.4 Document route migration matrix (old handler → new package) in backend README
- [x] 1.5 Add integration test harness with `CONSOLIDATED_MODE=true` on staging port

## 2. Phase 1 — Gateway rules + architecture

- [x] 2.1 Confirm single `IsRemoteEligibleGateway()` in `internal/domain/gateway.go`
- [x] 2.2 Remove or stub `essensys-support-site/backend/internal/gatewayrules/` with deprecation notice
- [x] 2.3 Refactor router to mount module sub-routers (`identity`, `admin`, `legacyiot`, `portal`, `gateway`)
- [x] 2.4 Ensure existing portal + gateway routes pass with `CONSOLIDATED_MODE=false` (no regression)
- [x] 2.5 Unit tests: gateway eligibility for `essensys-server`, `gw-essensys-gateway`, empty ID

## 3. Phase 2 — Identity module migration

- [x] 3.1 Migrate `handlers_auth.go` → `internal/identity/handlers.go`
- [x] 3.2 Migrate `handlers_oauth.go` → `internal/identity/oauth.go`
- [x] 3.3 Merge JWT middleware (emit + validate) in `internal/middleware/auth.go` + `jwt.go`
- [x] 3.4 Migrate `user_store.go` and `models/user.go` → `internal/data` + `internal/domain`
- [x] 3.5 Register routes: `/api/auth/*`, `/api/profile/*`, `/api/devices/nearby`
- [ ] 3.6 Integration tests: register, login, Google OAuth callback (mock), profile CRUD
- [ ] 3.7 Verify JWT from new backend works with `essensys-user-portal-frontend` inject flow

## 4. Phase 3 — Admin module migration

- [x] 4.1 Migrate `handlers_admin.go` → `internal/admin/handlers.go`
- [x] 4.2 Migrate `handlers_newsletter.go` → `internal/admin/newsletter.go`
- [x] 4.3 Migrate `audit_store.go` → `internal/data/audit_store.go`
- [x] 4.4 Register routes: `/api/admin/*`, `/api/newsletter/subscribe`
- [x] 4.5 Integration tests: admin stats, user role update, link assignment
- [ ] 4.6 Verify `essensys-support-site/site` Admin.jsx + UserManager.jsx against consolidated backend (staging)

## 5. Phase 4 — Legacy IoT module migration

- [x] 5.1 Migrate IoT handlers → `internal/legacyiot/handlers.go` (mystatus, serverinfos, myactions, infos)
- [x] 5.2 Port Basic Auth middleware (strict + optional) from support-site
- [x] 5.3 SQL migration `003_legacy_iot.sql`: tables `machines`, `machine_telemetry`, `gateway_push_status`
- [x] 5.4 Implement PG store replacing MemoryStore (interface + adapter)
- [x] 5.5 Script `cmd/import-machines/main.go` to import existing `machines.json`
- [x] 5.6 Integration tests: Basic Auth mystatus POST, serverinfos GET, myactions returns `{}`
- [x] 5.7 Verify admin machines/gateways list reads from PG

## 6. Phase 5 — Exchange sync (portal + gateway push)

- [x] 6.1 SQL migration `004_gateway_exchange_cache.sql`
- [x] 6.2 Implement `POST /api/gateway/exchange` in `internal/gateway/handlers.go`
- [x] 6.3 Replace stub `GET /api/portal/exchange` with cache read + stale metadata
- [x] 6.4 Extend `essensys-server-backend/internal/cloudsync` to push exchange on heartbeat
- [x] 6.5 Update `essensys-user-portal-frontend` to handle `stale` flag in exchange response
- [ ] 6.6 E2E test: inject shutter → exchange reflects state within 30s (CM5 lab)
- [x] 6.7 Fallback: serve `machine_telemetry` when cache empty (document staleness)

## 7. Phase 6 — Ansible single backend deploy

- [x] 7.1 Extend `portal_backend` role → `cloud_backend` (or merge `roles/backend` into `portal_backend`)
- [x] 7.2 Single systemd unit `essensys-cloud-backend.service` on `:8080`
- [x] 7.3 Merged `.env` template: OAuth, JWT, DB, NR, portal, gateway vars
- [x] 7.4 Update Nginx: remove `:8081` upstream; all `/api/` → `:8080`
- [x] 7.5 Add `cloud_backend_consolidated: true` and `cloud_backend_legacy_mode: true` rollback flag
- [x] 7.6 Update `essensys-ansible/docs/playbooks.md` and migration runbook
- [x] 7.7 Dry-run: `ansible-playbook -i inventory support-site.yml --check`

## 8. Phase 7 — Production cutover and deprecation

- [x] 8.1 Deploy consolidated backend to OVH staging/test
- [x] 8.2 Run Phase 0 WAN script + OAuth smoke tests on staging
- [x] 8.3 Production cutover: enable `cloud_backend_consolidated`, stop `essensys-portal-backend` :8081
- [ ] 8.4 Monitor New Relic APM for 24h; verify no 5xx spike on `/api/auth/*`, `/api/portal/inject`
- [x] 8.5 Mark `essensys-support-site/backend/` deprecated in README; archive git tag
- [ ] 8.6 Remove `backend/` directory from support-site repo (separate PR after soak period)
- [ ] 8.7 Rollback drill: `cloud_backend_legacy_mode: true` restores dual services

## 9. Phase 8 — E2E legacy armoire validation

- [x] 9.1 Document E2E checklist in `docs/cloud-backend-consolidation-e2e.md`
- [ ] 9.2 E2E: OAuth → link request → admin approve → portal inject → CM5 volet moves
- [ ] 9.3 E2E: WAN machine POST /api/mystatus → appears in admin machines list
- [ ] 9.4 E2E: `essensys-server` user sees LinkGate blocked (non-regression)
- [ ] 9.5 E2E: gateway offline → portal exchange shows stale/offline UI state
- [ ] 9.6 Sign-off: all acceptance criteria in specs satisfied
