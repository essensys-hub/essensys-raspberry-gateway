## 1. Phase 0 — Prérequis WAN HTTPS (gateway)

- [x] 1.1 Create `essensys-raspberry-gateway/scripts/test-wan-https-ovh.sh` (DNS, TLS, eth0 route, no HTTP hub URL)
- [x] 1.2 Run script on CM5 prod gateway and capture passing output (validé depuis poste dev ; à reproduire sur CM5 eth0)
- [x] 1.3 Add § Connectivité cloud to `essensys-ansible/docs/install-gateway.md` with checklist P0–P6

## 2. GitHub repos bootstrap

- [x] 2.1 Create `essensys-hub/essensys-user-portal-backend` (MIT, README, go.mod, Chi scaffold)
- [x] 2.2 Create `essensys-hub/essensys-user-portal-frontend` (MIT, README, Vite React TS Tailwind scaffold)
- [x] 2.3 Add GitHub Actions: backend `go test ./...`, frontend `npm run lint && npm run build`

## 3. Portal backend — data model and auth

- [x] 3.1 Add PostgreSQL migrations: `link_requests`, `cloud_actions`, `gateway_sessions`
- [x] 3.2 Implement JWT validation middleware (shared `JWT_SECRET` with support-site)
- [x] 3.3 Implement `POST /api/portal/link-request` and `GET /api/portal/link-request/status`
- [x] 3.4 Implement admin endpoints: list/approve/reject link requests
- [x] 3.5 Implement `GET /api/portal/health` and gateway stub routes returning 401 without token

## 4. Portal backend — cloud action queue

- [x] 4.1 Port order expansion logic (590 + 605..622) from edge `ActionService` patterns
- [x] 4.2 Implement `POST /api/portal/inject` with approved-link guard and GUID idempotence
- [x] 4.3 Implement `GET /api/gateway/pending-actions` (Bearer gateway token)
- [x] 4.4 Implement `POST /api/gateway/actions/{guid}/done` and `POST /api/gateway/heartbeat`
- [x] 4.6 Implement `GET /api/portal/exchange`, `GET /api/portal/history/latest`, `POST /api/portal/web/actions` (alarme 409–411)

## 5. Edge cloud sync (essensys-server-backend)

- [x] 5.1 Add `cloud` section to gateway `config.yaml` (`hub_url`, `gateway_token`, `poll_interval_seconds`)
- [x] 5.2 Implement `internal/cloudsync` poll loop (HTTPS only to `https://mon.essensys.fr`)
- [x] 5.3 Apply fetched actions via in-process `ActionService.AddAction()`
- [x] 5.4 Register gateway token in VPS `gateway_sessions` during provisioning (Ansible vault)
- [x] 5.5 Add unit tests for expansion parity with web inject

## 6. Portal frontend

- [x] 6.1 Copier l'UI complète depuis `essensys-server-frontend` (pages dashboard, sécurité, chauffage, éclairage, volets, eau, arrosage, notifications, réglages)
- [x] 6.2 Implement link-request gate screen (pending / rejected / approved states)
- [x] 6.3 Adapter `legacyApi.ts` vers `/api/portal/inject`, `/exchange`, `/history/latest`, `/web/actions` + JWT support-site
- [x] 6.4 Wire API client to `/api/portal/inject` with JWT from support-site session
- [x] 6.5 Add gateway online/offline badge from heartbeat API
- [x] 6.6 `npm run build` vert (Tailwind 4, base `/portal/`, sans UniFi)

## 7. Support-site admin extensions

- [x] 7.1 Add admin UI panel for pending link requests (list, approve, reject)
- [x] 7.2 On approve: call existing `PUT /api/admin/users/{id}/links` + update link request status
- [x] 7.3 Document admin workflow in `essensys-support-site/docs/`

## 8. Ansible deploy (same VPS OVH)

- [x] 8.1 Create role `portal_backend` (clone, build, systemd `:8081`, `.env`)
- [x] 8.2 Create role `portal_frontend` (clone, npm build, deploy dist)
- [x] 8.3 Create role `portal_nginx` (routes `/portal/`, `/api/portal/`, `/api/gateway/`)
- [x] 8.4 Extend `support-site.yml` with portal roles and document in `docs/playbooks.md`
- [x] 8.5 Deploy to OVH and verify `curl https://mon.essensys.fr/portal/` returns 200

## 9. End-to-end validation

- [x] 9.1 User OAuth login → submit link request → admin approves
- [x] 9.2 User opens portal → shutter action → cloud_actions row with full 590+605..622 block
- [x] 9.3 Gateway agent polls HTTPS → local Redis queue → BP_MQX_ETH executes → done ack
- [ ] 9.4 Confirm agent logs contain no `http://mon.essensys.fr`
- [ ] 9.5 Verify `install.gateway.yml` stack unchanged when `cloud.enabled: false`
