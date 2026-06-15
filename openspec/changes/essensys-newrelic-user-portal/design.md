## Context

Essensys operates the **remote user portal** on the OVH VPS at `https://mon.essensys.fr` (`essensys-user-portal-backend` on `:8081`, static SPA at `/portal/`, Nginx via `portal_nginx`). The portal was specified in change `essensys-remote-user-interface` and is deployed by `essensys-ansible/support-site.yml`. Edge gateways use **Prometheus** (`raspberry_prometheus`) for on-site metrics — a separate perimeter.

There is no SaaS observability for the cloud hub. Operators need visibility into portal API errors (especially `/api/portal/inject` and `/api/gateway/*`), frontend JS failures, and VPS resource usage. The prompt `prompts/NewRelicUserPortal.md` defines the target stack.

## Goals / Non-Goals

**Goals:**

- APM for `essensys-user-portal-backend` with Chi route-level transactions.
- Browser monitoring for SPA `/portal/*` with page views and JS/API errors.
- Infrastructure agent on OVH reporting host, Nginx, and PostgreSQL metrics.
- Ansible-managed deploy with vault secrets and `newrelic_enabled` feature flag.
- Zero behavioral change when New Relic is disabled.

**Non-Goals:**

- New Relic agents on CM5 / gateway (Prometheus remains).
- Replacing Prometheus or Alertmanager on edge.
- Instrumenting `essensys-support-site` backend `:8080` in this change.
- Session replay, log forwarding to NR (phase 2 optional).
- Custom NR dashboards for domotic KPIs in MVP.

## Decisions

### 1. New Relic on VPS only (complement Prometheus)

**Chosen**: Deploy NR on OVH hub; leave gateway Prometheus unchanged.

**Rationale**: Different operators and failure domains — cloud vs on-site LAN.

**Alternative**: Extend Prometheus to scrape VPS — rejected (no existing VPS Prometheus stack; NR account may already exist per ROI docs).

### 2. Backend: newrelic-go v3 + nrchi middleware

**Chosen**: Initialize `newrelic.Application` in `cmd/server/main.go` when `NEW_RELIC_ENABLED=true`; pass app pointer to `api.NewRouter`; wrap with `nrchi.Middleware`.

**Alternative**: OpenTelemetry exporter — rejected (NR account target; simpler NR-native UX).

### 3. Feature flag default off

**Chosen**: `NEW_RELIC_ENABLED=false` by default in code and Ansible; prod enables via inventory.

**Rationale**: Local dev and CI must not call NR SaaS or require license keys.

### 4. Frontend: npm `@newrelic/browser-agent` + Vite env

**Chosen**: Module `src/observability/newrelic.ts`; init in `main.tsx`; `VITE_NEW_RELIC_*` injected at Ansible build time.

**Alternative**: Inline script in `index.html` post-build — rejected (harder to type-check and test).

### 5. Ansible: dedicated role `newrelic_infra`

**Chosen**: New role installs APT package and templates `/etc/newrelic-infra.yml`; conditional on `newrelic_enabled`.

**Extend** existing `portal_backend` / `portal_frontend` roles rather than forking them.

### 6. Secrets in Ansible Vault

**Chosen**: `vault_newrelic_license_key` (and browser keys if distinct) in encrypted `group_vars`; never in git.

**Alternative**: External secret manager — deferred (VPS already uses Ansible patterns).

### 7. Sensitive data in traces

**Chosen**: Do not attach JWT, `Authorization`, gateway tokens, email, or domotic `v` values to NR custom attributes. Health and heartbeat routes excluded or lightly sampled.

### 8. NR entity naming

**Chosen**:

| Type | Name | Environment |
|------|------|-------------|
| APM | `essensys-user-portal-backend` | production |
| Browser | `essensys-user-portal-frontend` | production |
| Host | `ovh-mon-essensys` | production |

Tags: `service:user-portal`, `deployment:ovh-vps`, `domain:mon.essensys.fr`.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| NR ingest cost | Feature flag; exclude health/heartbeat noise; document estimated GB/month |
| PII in traces | Explicit deny-list for attributes; code review checklist |
| Browser key visible in JS bundle | NR domain whitelist; accept NR browser key model |
| CSP blocks NR script | Verify Nginx headers after deploy |
| Agent startup failure breaks backend | Init errors log warning only; server starts without NR |
| Ansible vault missing on deploy | Role defaults `newrelic_enabled: false`; clear docs |

## Migration Plan

1. **Phase 0**: Create NR account apps; store vault secrets; keep `newrelic_enabled: false`.
2. **Phase 1–2**: Merge backend + frontend code with flags off; CI green.
3. **Phase 3**: Deploy Ansible with `newrelic_enabled: true` on OVH; verify NR dashboards.
4. **Rollback**: Set `newrelic_enabled: false` and redeploy; or `NEW_RELIC_ENABLED=false` in `.env` only.

No database migration. No API contract changes.

## Open Questions

- Single license key vs separate Browser ingest key — confirm in NR account UI during Phase 0.
- Enable `nri-postgresql` in MVP or phase 2 — default **on** if low effort.
- Distributed tracing headers through Nginx — verify `traceparent` passthrough in `portal_nginx` templates.
