## Context

Essensys operates a **support portal** on OVH (`essensys-support-site`, deployed via `essensys-ansible/support-site.yml`) at `https://mon.essensys.fr` with PostgreSQL, OAuth (Google/Apple), JWT auth, and admin user management including `linked_machine_id` / `linked_gateway_id`. End users with a gateway on site (CM5 per `prompts/Gateway.md`) currently control domotics via **LAN** (`essensys-server-frontend` → local `POST /api/admin/inject` → Redis → BP_MQX_ETH on eth1 HTTP:80).

Remote users cannot use self-service `PUT /api/profile/links` (IP mismatch guard). The v1 prompt incorrectly assumed inbound HTTPS proxy to each customer's gateway WAN URL — rejected. The corrected model is a **cloud hub**: orders enqueue on OVH; gateway **outbound HTTPS:443** polls and applies locally via `ActionService.AddAction()`.

## Goals / Non-Goals

**Goals:**

- Remote domotic portal on **same VPS** as support-site (`/portal/*`, `/api/portal/*`, `/api/gateway/*`).
- **Admin-approved** link workflow before any domotic control.
- Order normalization parity: **590 + indices 605..622** before cloud persistence.
- Gateway agent in `essensys-server-backend` (`internal/cloudsync`) polling `https://mon.essensys.fr` only.
- Phase 0 WAN HTTPS validation script on CM5 before portal MVP.
- New repos `essensys-user-portal-backend` and `-frontend` with Ansible deploy roles.

**Non-Goals:**

- Removing on-site gateway or changing BP_MQX_ETH poll path (local HTTP:80).
- Control Plane (`:9100`) on VPS.
- Self-service pairing / QR without admin.
- Inbound connections from OVH to customer home IP.
- Multi-region SaaS, billing, native mobile app rewrites.

## Decisions

### 1. Hub cloud vs inbound proxy

**Chosen**: **Hub cloud** — VPS owns pending action queue; gateway pulls over outbound HTTPS.

**Alternatives**:
- BFF proxies to customer Traefik WAN URL — rejected (CORS, variable URLs, NAT, security).
- Move Redis to cloud — rejected (firmware latency, offline LAN requirement).

### 2. Portal repos: separate backend + frontend

**Chosen**: Two new repos mirroring `essensys-server-backend` / `-frontend` pattern:
- `essensys-user-portal-backend` — Go Chi, `:8081`
- `essensys-user-portal-frontend` — React 19, Vite, Tailwind

**Rationale**: Keeps support-site focused on admin/support; independent CI and versioning.

**Alternative**: Monolith extension of `essensys-support-site` — rejected (mixed bounded contexts).

### 3. Auth: shared JWT with support-site

**Chosen**: Portal-backend validates JWT signed with same `JWT_SECRET` as support-site. User identity and roles read from existing `users` table (shared PostgreSQL).

**Alternative**: Auth0/Supabase — rejected (NIH; OAuth already works on OVH).

### 4. Link workflow: new `link_requests` table + existing admin links

**Chosen**:
- User: `POST /api/portal/link-request` → `link_requests.status = pending`
- Admin: approves via support-site admin UI → `PUT /api/admin/users/{id}/links` + `PUT /api/portal/link-requests/{id}` → `approved`
- Portal UI checks: user has `linked_machine_id` AND approved request (or approved flag on request)

### 5. Cloud action queue: PostgreSQL on VPS

**Chosen**: Table `cloud_actions` (guid, user_id, machine_id, params JSONB, status, created_at). Normalization in portal-backend before insert.

**Alternative**: Redis on VPS — acceptable phase 2; PG simpler with existing stack.

### 6. Gateway agent: module in essensys-server-backend

**Chosen**: `internal/cloudsync` goroutine + config flags:
```yaml
cloud:
  enabled: true
  hub_url: "https://mon.essensys.fr"
  gateway_token: "<vault>"
  poll_interval_seconds: 5
```
Poll `GET /api/gateway/pending-actions`, apply via in-process `ActionService.AddAction()`, `POST /api/gateway/actions/{guid}/done`, `POST /api/gateway/heartbeat`.

**Alternative**: Separate `essensys-gateway-cloud-agent` binary — deferred unless packaging isolation required.

### 7. Local apply path

**Chosen**: Agent calls **in-process** `ActionService.AddAction()` (same code path as web inject), not HTTP loopback — avoids Nginx auth edge cases.

**Fallback**: `POST http://127.0.0.1:7070/api/admin/inject` only if in-process injection unavailable in deployment mode.

### 8. Nginx on OVH (portal_nginx role)

**Chosen** routes on existing Nginx host:
| Path | Target |
|------|--------|
| `/portal/` | `/opt/essensys/portal-frontend/dist/` |
| `/api/portal/` | `127.0.0.1:8081` |
| `/api/gateway/` | `127.0.0.1:8081` (Bearer gateway token) |

Support-site routes unchanged (`/api/` → `:8080`).

### 9. UI source: copy/adapt from essensys-server-frontend

**Chosen**: Initial copy of `legacyApi.ts` mapping + `ShuttersPage` / light pages into portal-frontend; extract shared package `@essensys/domotic-ui` as **phase 2** if duplication hurts.

### 10. Gateway token

**Chosen**: Per-installation Bearer token generated at provisioning, stored in Ansible vault (`cloud_gateway_token`), registered in VPS table `gateway_sessions` (gateway_id, token_hash, last_seen).

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Customer firewall blocks outbound HTTPS | Phase 0 checklist; document required egress :443 |
| Poll latency (5s default) | Configurable interval; UI shows pending state |
| Duplicate actions (retry) | GUID idempotence on cloud_actions + done ack |
| JWT secret leak | Vault-only deploy; rotate procedure in Ansible docs |
| Portal-backend down | Gateway keeps local LAN control; cloud queue drains when back |
| Order expansion drift vs edge | Shared test vectors from essensys-backend-reference-orders skill |
| Admin bottleneck on link requests | Email/notification hook phase 2 |

## Migration Plan

1. **Phase 0**: Run `scripts/test-wan-https-ovh.sh` on CM5 prod; document in `install-gateway.md`.
2. **Phase 1**: Create GitHub repos + CI; stub gateway API routes returning 401.
3. **Phase 2**: Deploy portal-backend/frontend on OVH staging path (or maintenance subdomain).
4. **Phase 3**: Enable `cloudsync` on one pilot gateway; E2E volet test.
5. **Phase 4**: Admin link workflow live; limited user beta.
6. **Rollback**: Disable `cloud.enabled` on gateway; remove Nginx portal routes; queue retained in PG for replay.

## Open Questions

- Notification channel for pending link requests (email vs admin dashboard only)?
- Rate limits: per-user inject cap per minute?
- Should approved link expire if gateway offline > N days?
- Shared `@essensys/domotic-ui` npm package timeline?
