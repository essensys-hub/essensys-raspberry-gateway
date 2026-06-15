## 1. Phase 0 — Compte New Relic et secrets (manuel — opérateur)

- [ ] 1.1 Create or confirm New Relic account / sub-account for Essensys
- [ ] 1.2 Generate Ingest License key and store in Ansible Vault as `vault_newrelic_license_key`
- [ ] 1.3 Create APM app `essensys-user-portal-backend` and Browser app `essensys-user-portal-frontend`
- [ ] 1.4 Restrict Browser app domain whitelist to `mon.essensys.fr`
- [ ] 1.5 Record account ID, browser application ID, agent ID, trust key in vault or encrypted inventory

> Voir `essensys-ansible/docs/newrelic.md` § Prérequis.

## 2. Backend APM — `essensys-user-portal-backend`

- [x] 2.1 Add `newrelic-go` and `nrgochi` dependencies to `go.mod`
- [x] 2.2 Implement NR app init in `cmd/server/main.go` with `NEW_RELIC_ENABLED` guard
- [x] 2.3 Pass `*newrelic.Application` to `api.NewRouter` and register `nrgochi.Middleware`
- [x] 2.4 Exclude or ignore `GET /api/portal/health` from APM transactions
- [x] 2.5 Ensure no JWT/tokens/domotic payloads in custom attributes
- [x] 2.6 Add unit test: server/router works with `NEW_RELIC_ENABLED=false`
- [x] 2.7 Document env vars in README
- [x] 2.8 Verify `go test ./...` passes in CI

## 3. Frontend Browser — `essensys-user-portal-frontend`

- [x] 3.1 Add `@newrelic/browser-agent` dependency
- [x] 3.2 Create `src/observability/newrelic.ts` with init no-op when disabled
- [x] 3.3 Call `initNewRelic()` from `src/main.tsx`
- [x] 3.4 Add React Router page view tracking for `/portal/*`
- [x] 3.5 Report API 5xx/network errors from `portalApi.ts` without Authorization values
- [x] 3.6 Document `VITE_NEW_RELIC_*` variables in README
- [x] 3.7 Verify `npm run build` passes (lint : erreurs préexistantes hors périmètre NR)

## 4. Ansible — `essensys-ansible`

- [x] 4.1 Create role `newrelic_infra` (defaults, tasks, template, handlers)
- [x] 4.2 Add APT repo + package install for `newrelic-infra` (conditional on `newrelic_enabled`)
- [x] 4.3 Template `/etc/newrelic-infra.yml` with vault license key and display name
- [x] 4.4 Optional: enable nri-nginx and nri-postgresql integrations via variables
- [x] 4.5 Extend `portal_backend` to template NR vars into `.env` (Jinja template)
- [x] 4.6 Extend `portal_frontend` to pass `VITE_NEW_RELIC_*` to `npm run build`
- [x] 4.7 Add `newrelic_infra` to `support-site.yml` after `common`
- [x] 4.8 Add `group_vars/essensys/newrelic.example.yml` and document vault workflow
- [x] 4.9 Write `docs/newrelic.md` with deploy, verify, rollback checklist

## 5. Validation prod OVH (manuel — après déploiement)

- [ ] 5.1 Deploy with `newrelic_enabled: true` on OVH VPS
- [ ] 5.2 Confirm `systemctl is-active newrelic-infra` and `essensys-portal-backend`
- [ ] 5.3 Verify APM transactions for `POST /api/portal/inject` and gateway routes in NR UI
- [ ] 5.4 Open `https://mon.essensys.fr/portal/` and confirm Browser page views within 5 minutes
- [ ] 5.5 Confirm host metrics visible for `ovh-mon-essensys`
- [ ] 5.6 Run rollback test: `newrelic_enabled: false` redeploy — portal still functional
- [ ] 5.7 Gitleaks / manual review: no license keys in git history

## 6. Phase 2 (optionnel — hors MVP)

- [ ] 6.1 Forward `journalctl` logs from `essensys-portal-backend` to New Relic
- [ ] 6.2 Create NR dashboard: inject latency, gateway heartbeats, JS error rate
- [ ] 6.3 Configure basic NR alerts (error rate, host down)
