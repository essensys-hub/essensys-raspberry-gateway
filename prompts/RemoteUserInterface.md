# Prompt : portail utilisateur distant — `mon.essensys.fr` (OVH), liaison admin, gateway HTTPS

Tu es un ingénieur **full-stack (Go + React/TypeScript) + Ansible + architecture distribuée**. Ta mission est de **concevoir et spécifier** (puis implémenter via OpenSpec) un **portail domotique** pour les utilisateurs Essensys qui **n’administrent pas** la gateway (CM5 / Pi) sur site, en s’appuyant sur l’**infrastructure existante OVH** (`essensys-support-site`, PostgreSQL, OAuth) et un déploiement **Ansible** (`essensys-ansible/support-site.yml`).

Respecte **Clean Architecture / DDD** : bounded contexts, use cases isolés, **pas de logique métier dans les composants React**, **pas de Redis exposé au navigateur**. Applique **library-first** : réutiliser auth, users et admin de `essensys-support-site` avant tout NIH.

**Contrainte firmware** : BP_MQX_ETH continue de poller un backend en **HTTP :80** sur le segment armoire (eth1). La gateway **reste sur site** ; le portail vit sur le **VPS**, pas sur le Pi.

---

## 0. Autocritique du prompt v1 (écarts corrigés)

Le premier jet du prompt (`RemoteUserInterface.md` v1) contenait des **hypothèses incorrectes ou incomplètes**. Les corriger est obligatoire avant OpenSpec / implémentation.

| Écart v1 | Problème | Correction v2 |
|----------|----------|---------------|
| **Hébergement flou** | « VPS ou sous-domaine dédié » sans ancrage produit | **Même VPS OVH** que `essensys-support-site`, domaine **`https://mon.essensys.fr`**, playbook **`support-site.yml`** étendu |
| **Base utilisateurs** | OAuth mentionné mais pas l’existant PG/users | **Réutiliser** la table `users`, rôles, JWT, Google/Apple déjà en prod sur OVH |
| **Liaison armoire** | Pairing self-service / QR code | **Workflow admin** : l’utilisateur **dépose une demande** ; un **admin** (`admin_global` / `support`) **approuve** et lie `linked_machine_id` + `linked_gateway_id` — pas de linking auto sans validation |
| **Sens des flux** | BFF cloud → proxy HTTPS **vers l’URL WAN de chaque gateway** (modèle inbound variable) | **Prérequis** : la gateway **initie** des appels **sortants** vers **`https://mon.essensys.fr:443`** (HTTPS WAN, **jamais HTTP** pour ce canal). File d’actions / heartbeat / sync **centrés sur le VPS** |
| **Repos** | Extension monolithique de `essensys-support-site` ou noms vagues | **Créer de nouveaux dépôts** dans [essensys-hub](https://github.com/orgs/essensys-hub/repositories), déployés sur le **même VPS** via Ansible |
| **Option D (proxy direct WAN)** | Suggérée comme fallback | **Rejetée** : CORS, credentials, URLs clientes non normalisées, pas aligné OVH |
| **Self-link IP** | Non documenté | `PUT /api/profile/links` existe mais impose **IP match** — **insuffisant** pour utilisateur distant ; le portail repose sur **liaison admin** |

**Décision architecture v2 (à valider dans design.md)** : modèle **hub cloud** — l’UI sur `mon.essensys.fr` écrit les ordres normalisés côté VPS ; un **agent gateway** (module dans `essensys-server-backend` ou binaire dédié) **poll en HTTPS** le VPS, réinjecte localement via `ActionService.AddAction()` / Redis edge, BP_MQX_ETH lit toujours le Redis **local**.

---

## 1. Contexte produit (état OVH aujourd’hui)

### 1.1 Infrastructure existante

| Composant | Détail |
|-----------|--------|
| **Hébergeur** | VPS OVH (Ubuntu) |
| **Playbook** | `essensys-ansible/support-site.yml` → rôles `common`, `database`, `backend`, `frontend` |
| **Repo déployé** | `essensys-hub/essensys-support-site` → `/opt/essensys/` |
| **URL prod** | `https://mon.essensys.fr/` (`FRONTEND_URL` dans `.env` backend) |
| **Stack** | Nginx → Go Chi (:8080) + React Vite (`site/`) + PostgreSQL |
| **Auth** | OAuth Google/Apple, JWT, rôles (`admin_global`, `admin_local`, `user`, `guest_local`, `support`) |
| **Liaison devices** | `users.linked_machine_id`, `users.linked_gateway_id` ; admin via `UserManager.jsx` + `PUT /api/admin/users/{id}/links` |

### 1.2 Ce qu’on ajoute (MVP)

- **Portail domotique** (volets, lumières, dashboard) pour utilisateurs **`user`** déjà inscrits sur `mon.essensys.fr`.
- **Workflow demande → approbation admin** avant accès domotique.
- **Nouveaux repos** (front + back portail) + rôles Ansible sur le **même VPS**.
- **Prérequis gateway** : prouver que `essensys-raspberry-gateway` (CM5 prod) communique avec `mon.essensys.fr` en **HTTPS:443**.

### 1.3 Personas

| Persona | Action |
|---------|--------|
| **Utilisateur final** | S’inscrit (OAuth) → **demande l’accès** à son armoire → attend validation → utilise le portail |
| **Admin Essensys** | Reçoit la demande → vérifie identité / n° série → **lie** machine + gateway au compte → active le portail |
| **Installateur** | Installe la gateway sur site ; fournit identifiants machine au support |
| **Gateway CM5** | Agent HTTPS sortant vers OVH ; Redis/API locaux inchangés pour BP_MQX_ETH |

### 1.4 Non-objectifs MVP

- Remplacer la gateway ou le firmware.
- Control Plane ops (`:9100`) sur le VPS.
- Facturation SaaS / multi-région.
- Apps natives Android/iOS (parité API seulement).
- Linking self-service sans admin (l’IP-match actuel reste pour cas LAN installateur, pas pour le portail distant).

---

## 2. Architecture cible (hub OVH + agent gateway HTTPS)

### 2.1 Schéma logique

```text
┌──────────────────────────────────────────────────────────────────────────┐
│  VPS OVH — https://mon.essensys.fr (:443 TLS, Let's Encrypt)             │
│  ┌─────────────────────┐  ┌──────────────────────┐  ┌─────────────────┐ │
│  │ essensys-support-site│  │ essensys-user-portal │  │ PostgreSQL      │ │
│  │ (auth, admin, users) │  │ -backend (BFF)       │  │ link_requests   │ │
│  │                      │  │ essensys-user-portal │  │ action_queue    │ │
│  │                      │  │ -frontend (UI domo)  │  │ gateway_sessions│ │
│  └──────────┬───────────┘  └──────────┬───────────┘  └─────────────────┘ │
│             │ JWT partagé / SSO         │                                │
│             └───────────────────────────┘                                │
│                          ▲                                               │
│                          │ HTTPS:443 ONLY (WAN, sortant depuis gateway)   │
└──────────────────────────┼───────────────────────────────────────────────┘
                           │
┌──────────────────────────┼───────────────────────────────────────────────┐
│  Site client — essensys-raspberry-gateway (CM5)                          │
│  eth0 → Internet → curl/agent → https://mon.essensys.fr/api/gateway/...  │
│  eth1 :80 HTTP → BP_MQX_ETH GET /api/myactions (inchangé, local)       │
│  Redis local ← ActionService.AddAction() ← agent après poll cloud        │
└──────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Flux utilisateur (demande admin)

```text
1. User OAuth login sur mon.essensys.fr (support-site existant)
2. POST /api/portal/link-request { machine_serial, message }
   → statut: pending
3. Admin voit file dans /admin (support-site ou portail admin)
4. Admin PUT /api/admin/users/{id}/links { linked_machine_id, linked_gateway_id }
   + PUT /api/portal/link-request/{id} { status: approved }
5. User accède /portal/dashboard (essensys-user-portal-frontend)
6. Si pending/rejected → écran explicite, pas de boutons domotique
```

### 2.3 Flux ordre domotique (normalisation obligatoire)

```text
User UI → POST https://mon.essensys.fr/api/portal/inject { k, v }
       → user-portal-backend vérifie JWT + link approved + machine_id
       → expansion 590 + 605..622 (même sémantique ActionService.AddAction)
       → persistance file cloud (PG ou Redis VPS)
Gateway agent → GET https://mon.essensys.fr/api/gateway/pending-actions
              (Header: Authorization: Bearer <gateway_token>, HTTPS:443)
       → pour chaque action: POST local http://127.0.0.1:80/api/admin/inject
         OU appel direct ActionService (préféré: même code path que web local)
       → POST https://mon.essensys.fr/api/gateway/actions/{guid}/done
BP_MQX_ETH → GET http://mon.essensys.fr/api/myactions (eth1, HTTP:80 local only)
```

> **Distinction ports** : **443 HTTPS** = canal **gateway ↔ OVH** et **navigateur ↔ OVH** ; **80 HTTP** = **uniquement** segment armoire **local**, jamais exposé sur Internet.

### 2.4 Use cases (noms domaine)

| Use case | Module |
|----------|--------|
| `SubmitArmoireLinkRequest` | user-portal-backend |
| `ApproveArmoireLinkRequest` | support-site admin (existant étendu) |
| `AuthenticatePortalUser` | JWT support-site (réutilisation) |
| `EnqueueDomoticOrder` | expansion 590+605..622, file cloud |
| `PollCloudActions` | agent gateway HTTPS |
| `ApplyCloudOrderLocally` | edge → ActionService.AddAction |
| `ReportGatewayHeartbeat` | HTTPS → VPS, statut UI « en ligne » |

---

## 3. Prérequis technique — gateway → `mon.essensys.fr` HTTPS

**Bloquant avant MVP portail** : prouver sur une gateway réelle (`essensys-raspberry-gateway`, CM5 prod) que le trafic **sortant eth0** atteint OVH en **TLS sur le port 443**.

### 3.1 Checklist prérequis (tasks OpenSpec phase 0)

| # | Test | Commande / critère | Attendu |
|---|------|-------------------|---------|
| P0 | Résolution DNS | `dig +short mon.essensys.fr` depuis gateway | IP publique OVH |
| P1 | TLS handshake | `curl -sS -o /dev/null -w '%{http_code}\n' https://mon.essensys.fr/` | `200` ou `301` |
| P2 | Certificat valide | `curl -vI https://mon.essensys.fr/ 2>&1 \| grep -i subject` | Let's Encrypt, SAN `mon.essensys.fr` |
| P3 | **Pas de HTTP WAN** | `curl -sS -o /dev/null -w '%{http_code}\n' http://mon.essensys.fr/` | **Échec**, redirect 301→HTTPS, ou **refus** — le canal agent **ne doit pas** utiliser `:80` vers OVH |
| P4 | API gateway stub | `curl -sS -X POST https://mon.essensys.fr/api/gateway/heartbeat -H 'Authorization: Bearer …'` | `401` sans token (route existe) ou `200` avec token test |
| P5 | Sortie eth0 | Vérifier route par défaut **eth0**, pas eth1 | `ip route get $(dig +short mon.essensys.fr)` → dev eth0 |
| P6 | Pare-feu / NAT | Box cliente autorise HTTPS sortant | Documenter si blocage |

### 3.2 Livrable prérequis

- Script `essensys-raspberry-gateway/scripts/test-wan-https-ovh.sh` (ou rôle Ansible `gateway_cloud_connectivity`).
- Entrée dans `essensys-ansible/docs/install-gateway.md` § « Connectivité cloud ».
- Capture logs : **aucun** appel agent vers `http://mon.essensys.fr` (grep logs).

### 3.3 Configuration gateway (à spécifier)

Variables Ansible / `config.yaml` backend edge :

```yaml
cloud_hub_url: "https://mon.essensys.fr"   # PAS http://
cloud_gateway_token: "{{ vault_cloud_gateway_token }}"
cloud_poll_interval_seconds: 5
```

Agent : timer systemd ou goroutine dans backend — **une seule** implémentation à choisir dans design.md.

---

## 4. Nouveaux dépôts GitHub (essensys-hub)

Créer **avant** l’implémentation, dans [essensys-hub](https://github.com/orgs/essensys-hub/repositories), en suivant les conventions des repos existants (`essensys-server-backend`, `essensys-server-frontend`, MIT, CI GitHub Actions).

### 4.1 `essensys-user-portal-backend`

| Attribut | Valeur |
|----------|--------|
| **Rôle** | BFF domotique sur VPS : file d’actions, inject normalisé, API gateway HTTPS, link requests |
| **Stack** | Go, Chi, PostgreSQL (même instance OVH ou schema dédié `portal`) |
| **Auth** | Valide JWT émis par `essensys-support-site` (secret partagé ou introspection) |
| **Port** | `:8081` (éviter conflit `:8080` support-site) |
| **Structure** | `cmd/server`, `internal/domain`, `internal/api`, `internal/data` — **pas** de package `utils` |

### 4.2 `essensys-user-portal-frontend`

| Attribut | Valeur |
|----------|--------|
| **Rôle** | SPA domotique (`/portal/*`) : dashboard, volets, lumières |
| **Stack** | React 19, TypeScript, Vite, Tailwind — aligné `essensys-server-frontend` |
| **Source UI** | Extraire / copier mapping indices depuis `legacyApi.ts`, `ShuttersPage.tsx` |
| **Build** | `dist/` servi par Nginx sur le VPS |

### 4.3 `essensys-gateway-cloud-agent` (optionnel — ou module edge)

| Attribut | Valeur |
|----------|--------|
| **Rôle** | Poll HTTPS OVH, heartbeat, application locale des ordres |
| **Alternative** | Module `internal/cloudsync` dans `essensys-server-backend` — **préférer** si un seul binaire edge |
| **Décision** | À trancher design.md ; le prompt exige **au minimum** une spec capability `gateway-cloud-agent` |

### 4.4 Bootstrap repo (template tâche OpenSpec)

```bash
# Exemple création (org essensys-hub, GitHub CLI)
gh repo create essensys-hub/essensys-user-portal-backend --public --license mit
gh repo create essensys-hub/essensys-user-portal-frontend --public --license mit
# README, .github/workflows/build.yml, go.mod / package.json
```

---

## 5. Déploiement Ansible (même VPS OVH)

Étendre **`essensys-ansible/support-site.yml`** — **ne pas** créer un VPS séparé.

### 5.1 Nouveaux rôles suggérés

| Rôle | Responsabilité |
|------|----------------|
| `portal_backend` | Clone `essensys-user-portal-backend`, build Go, systemd `:8081`, `.env` |
| `portal_frontend` | Clone `essensys-user-portal-frontend`, `npm run build`, deploy `dist/` |
| `portal_nginx` | Snippets Nginx : `/portal/` → static, `/api/portal/` → :8081, `/api/gateway/` → :8081 |

### 5.2 Nginx sur OVH (extrait attendu)

```nginx
# /api/portal/ → user-portal-backend:8081
# /portal/     → /opt/essensys/portal-frontend/dist/
# /api/gateway/→ user-portal-backend:8081 (mTLS ou Bearer gateway token)
```

### 5.3 Variables Ansible (group_vars)

```yaml
portal_backend_repo: "https://github.com/essensys-hub/essensys-user-portal-backend.git"
portal_frontend_repo: "https://github.com/essensys-hub/essensys-user-portal-frontend.git"
portal_backend_port: 8081
cloud_hub_public_url: "https://mon.essensys.fr"
```

### 5.4 Ordre playbook

```yaml
# support-site.yml (étendu)
roles:
  - common
  - database
  - backend          # essensys-support-site (inchangé)
  - frontend         # essensys-support-site (inchangé)
  - portal_backend   # NOUVEAU
  - portal_frontend  # NOUVEAU
  - portal_nginx     # NOUVEAU ou extension role nginx existant
```

---

## 6. Flux ordres — rappel essensys-backend-reference-orders

| Règle | Application portail |
|-------|---------------------|
| Bloc `590 + 605..622` | Expansion dans **user-portal-backend** avant enqueue cloud |
| Pas d’inject partiel MCP-style | Interdit depuis UI |
| `613` seul | Insuffisant ; documenter |
| BP_MQX_ETH | Lit **Redis local** après application par l’agent — **pas** Redis OVH direct |

---

## 7. Livrables OpenSpec

Change : **`essensys-remote-user-interface`** dans  
`essensys-raspberry-gateway/openspec/changes/essensys-remote-user-interface/`.

```bash
cd essensys-raspberry-gateway
openspec new change "essensys-remote-user-interface"
```

Ou : **`/openspec propose @prompts/RemoteUserInterface.md`**

### 7.1 Capabilities (specs/)

| Capability | Contenu |
|------------|---------|
| `ovh-hub-architecture` | VPS unique, mon.essensys.fr, séparation 443 WAN / 80 armoire local |
| `admin-link-request-workflow` | Demande user, approbation admin, états pending/approved/rejected |
| `portal-user-auth` | JWT support-site, garde-fou link approved |
| `cloud-action-queue` | Enqueue normalisé, idempotence GUID |
| `gateway-https-agent` | Poll/done/heartbeat vers `https://mon.essensys.fr:443` |
| `gateway-wan-prerequisite` | Script + checklist §3 |
| `domotic-ui-portal` | Frontend volets/lumières MVP |
| `github-repos-bootstrap` | Création essensys-user-portal-* + CI |
| `ansible-portal-deploy` | Rôles portal_* sur support-site.yml |

### 7.2 Phases tasks.md

1. **Phase 0** — Prérequis WAN HTTPS (§3) sur CM5 prod  
2. **Phase 1** — Création repos GitHub + CI  
3. **Phase 2** — OpenSpec + schéma PG (`link_requests`, `cloud_actions`)  
4. **Phase 3** — user-portal-backend + workflow demande/admin  
5. **Phase 4** — Agent gateway HTTPS  
6. **Phase 5** — user-portal-frontend (volets prioritaires)  
7. **Phase 6** — Ansible portal_* + deploy OVH  
8. **Phase 7** — E2E : demande → admin → inject cloud → agent → volet bouge  

---

## 8. Critères d’acceptation

- [ ] Utilisateur **sans** link approuvé → message clair, **pas** de contrôles domotique.
- [ ] Admin approuve → user voit dashboard portail sur `https://mon.essensys.fr/portal/`.
- [ ] Inject portail produit bloc **590+605..622** en file cloud (inspect PG).
- [ ] Gateway agent poll **HTTPS:443** uniquement ; logs sans `http://mon.essensys.fr`.
- [ ] Action arrive dans Redis **local** et BP_MQX_ETH l’exécute (test volet réel).
- [ ] `support-site.yml` déploie support + portail sur **même VPS**.
- [ ] Repos `essensys-user-portal-backend` et `-frontend` existent sous essensys-hub.
- [ ] Checklist §3 passée sur `essensys-raspberry-gateway` CM5.
- [ ] `install.gateway.yml` / stack edge **non régressée**.

---

## 9. Sécurité

- Token gateway **par installation**, stocké vault Ansible, rotation documentée.
- Rate limit `/api/portal/inject` et `/api/gateway/*`.
- Admin audit : qui a approuvé quel link request.
- Secrets `.p8` / `.env` **jamais** commités (Gitleaks).
- CORS : origine `https://mon.essensys.fr` uniquement pour portail.

---

## 10. Références

| Ressource | Chemin |
|-----------|--------|
| Support site OVH | `essensys-support-site/`, `essensys-ansible/support-site.yml` |
| Admin link users | `essensys-support-site/site/src/pages/UserManager.jsx` |
| Modèle User | `essensys-support-site/backend/internal/models/user.go` |
| Gateway CM5 | `essensys-raspberry-gateway/prompts/Gateway.md` |
| Install gateway | `essensys-ansible/docs/install-gateway.md` |
| Frontend local (source UI) | `essensys-server-frontend/src/services/legacyApi.ts` |
| Flux ordres | skill `essensys-backend-reference-orders` |
| Org GitHub | [essensys-hub/repositories](https://github.com/orgs/essensys-hub/repositories) |
| Newsletter volets (UX) | `essensys-doc/newsletters/2026-06-volets/NEWSLETTER.md` |

---

## 11. Résumé livraison agent

1. **Autocritique v1** intégrée (§0) — ne pas reprendre pairing self-service ni proxy WAN inbound.
2. OpenSpec **`essensys-remote-user-interface`** complet.
3. **Phase 0** prérequis HTTPS exécutée sur CM5.
4. **2 repos** essensys-hub créés + Ansible étendu.
5. Parcours **demande → admin → portail** démontré bout en bout.
