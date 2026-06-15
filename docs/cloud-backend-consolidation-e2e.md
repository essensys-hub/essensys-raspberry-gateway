# E2E — consolidation backend cloud (essensys-cloud-backend-consolidation)

Checklist de validation après déploiement. Prérequis : gateway CM5 avec `cloud.enabled: true`, compte utilisateur avec liaison approuvée.

!!! info "Prod juin 2026"
    Cutover effectué : hub unique `essensys-cloud-backend` sur `:8080`.  
    Voir [Cloud backend consolidation](acces/cloud-backend-consolidation.md).

## 0. Smoke HTTP (post-cutover)

- [x] `GET https://mon.essensys.fr/api/portal/health` → 200
- [x] `GET https://mon.essensys.fr/api/serverinfos` → JSON legacy
- [x] `GET /api/admin/stats` avec ADMIN_TOKEN → machines PG
- [ ] Pas de 502 sur `/api/portal/*` (snippet nginx consolidé)

## 1. Portail distant (CM5)

- [ ] Login OAuth sur `https://mon.essensys.fr`
- [ ] Demande liaison approuvée ; `GET /api/portal/link-request/status` → `portal_access: true`
- [ ] `POST /api/portal/inject` (volet) → action dans `cloud_actions`
- [ ] Volet physique bouge (< 60 s)
- [ ] `GET /api/portal/exchange?keys=605,613` → valeurs non vides, `stale: false` après push gateway
- [ ] Arrêt cloudsync → `stale: true` ou gateway offline dans l’UI (< 3 min)

## 2. IoT WAN passif (post Phase 4)

- [ ] Machine legacy `POST /api/mystatus` → visible dans admin machines

## 3. Non-régression essensys-server

- [ ] Utilisateur lié à `essensys-server` → LinkGate bloque le portail

## 4. Rollback

- [ ] `cloud_backend_legacy_mode: true` + redeploy Ansible → dual backend `:8080` + `:8081`
