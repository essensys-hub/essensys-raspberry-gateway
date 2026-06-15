## Why

Essensys end users who do not manage a local gateway (CM5 / Pi) need a **remote domotic portal** on the existing OVH VPS (`https://mon.essensys.fr`), built on the **support-site user base** (OAuth, PostgreSQL) with **admin-approved linking** of their armoire. Today, control is LAN-only or requires manual backend URL configuration; the hub-cloud model (gateway polls OVH over **HTTPS:443**, local Redis unchanged for BP_MQX_ETH) closes this gap without breaking firmware constraints.

## What Changes

- **New GitHub repos** under [essensys-hub](https://github.com/orgs/essensys-hub/repositories): `essensys-user-portal-backend` (BFF, `:8081`) and `essensys-user-portal-frontend` (SPA `/portal/*`).
- **Hub cloud on OVH**: normalized action queue on VPS; user inject via `/api/portal/inject`; gateway agent polls `/api/gateway/pending-actions` over **HTTPS only**.
- **Admin link-request workflow**: user submits request → admin approves and sets `linked_machine_id` / `linked_gateway_id` (extends existing support-site admin).
- **Gateway cloud sync module** in `essensys-server-backend` (`internal/cloudsync`) — poll OVH, apply locally via `ActionService.AddAction()`, heartbeat.
- **Phase 0 prerequisite**: WAN HTTPS connectivity script and checklist (gateway eth0 → `mon.essensys.fr:443`, never HTTP to OVH).
- **Ansible extension**: `essensys-ansible/support-site.yml` gains roles `portal_backend`, `portal_frontend`, `portal_nginx` on the **same VPS**.
- **Non-goals (MVP)**: replace edge gateway, Control Plane on VPS, self-service pairing without admin, inbound proxy to per-customer WAN URLs.

## Capabilities

### New Capabilities

- `ovh-hub-architecture`: Single OVH VPS hosting support-site + user portal; port separation (443 WAN cloud/browser vs 80 local armoire only).
- `admin-link-request-workflow`: User link requests with pending/approved/rejected states; admin approval ties to existing user link fields.
- `portal-user-auth`: JWT validation shared with support-site; portal access gated on approved link.
- `cloud-action-queue`: Normalized domotic orders (590 + 605..622) persisted on VPS with GUID idempotence.
- `gateway-https-agent`: Outbound HTTPS agent on edge — poll, apply locally, done, heartbeat to `mon.essensys.fr`.
- `gateway-wan-prerequisite`: Script and validation checklist proving eth0 → OVH HTTPS before portal MVP.
- `domotic-ui-portal`: React portal pages (dashboard, volets, lights) sourced from server-frontend patterns.
- `github-repos-bootstrap`: Create and CI-bootstrap `essensys-user-portal-backend` and `-frontend` repos.
- `ansible-portal-deploy`: Ansible roles and Nginx routes deploying portal on existing support-site VPS.

### Modified Capabilities

*(none — new cross-repo capability set; existing gateway dual-NIC and support-site behavior unchanged when portal disabled)*

## Impact

- **New repos**: `essensys-hub/essensys-user-portal-backend`, `essensys-hub/essensys-user-portal-frontend`.
- **Modified repos**: `essensys-server-backend` (cloudsync agent), `essensys-support-site` (admin UI for link requests, optional), `essensys-ansible` (`support-site.yml`, new roles, `install-gateway.md`), `essensys-raspberry-gateway` (prerequisite script).
- **APIs**: New `/api/portal/*` and `/api/gateway/*` on OVH; no public Redis exposure.
- **Dependencies**: Shared JWT secret between support-site and portal-backend; PostgreSQL schema `portal` or tables on existing DB.
- **Risk**: Gateway outbound HTTPS blocked on customer networks; mitigated by Phase 0 checklist and documented firewall requirements.
