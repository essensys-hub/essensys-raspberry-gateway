# Cloud sync (agent portail distant)

Le module **`internal/cloudsync`** du backend gateway (`essensys-server-backend`) synchronise les actions du portail OVH vers la file locale Redis et exécute le **scheduler de sync planifiée** vers le cloud.

## Activation

`config.yaml` sur la gateway :

```yaml
cloud:
  enabled: true
  hub_url: "https://mon.essensys.fr"
  gateway_id: "gw-essensys-gateway"   # optionnel si dérivé de MAC
  gateway_token: "<token Ansible vault>"
  poll_interval_seconds: 5
  scheduled_sync_enabled: true
```

!!! danger "HTTPS uniquement"
    `hub_url` doit être `https://mon.essensys.fr`. Aucun agent ne doit utiliser `http://` vers le hub WAN.

## Scheduler planifié (profils 3 h)

Profils PostgreSQL OVH (`sync_profiles`, migration 007) — admin **Sync Cloud** sur `mon.essensys.fr`.

| Profil | Plage |
|--------|-------|
| Zone Jour | 13–96 |
| Zone Nuit | 97–180 |
| SDB1 | 181–264 |
| SDB2 | 265–348 |
| Modes | 349–352 |
| Volets | 566–585 |
| **Scénarios** | **591–919** (excl. push 590) |

Par tick : `GET /api/gateway/sync-config` → runs `pending` → pull (`ExchangePullScheduler`) → push `POST /api/gateway/exchange`.

Toggle scénarios (LAN) : **Paramètres → Synchronisation** ou `PUT /api/admin/scenarios/sync` avec `{"enabled": true|false}`.

Statut LAN read-only :

```bash
curl -sS http://127.0.0.1:7070/api/admin/cloudsync/status | jq .
```

Ansible : `cloud_sync_enabled`, `cloud_scheduled_sync_enabled`, vault `cloud_gateway_token`.

Désactiver le scheduler (poll actions conservé) : `scheduled_sync_enabled: false`.

## Cycle de poll (actions cloud)

1. `GET https://mon.essensys.fr/api/gateway/pending-actions` (Bearer + headers MAC)
2. Expansion / injection via `ActionService.AddAction()` (même logique que `/api/admin/inject`)
3. `POST .../api/gateway/actions/{guid}/done` après exécution
4. `POST .../api/gateway/heartbeat` périodique

## Enregistrement OVH

Lors du déploiement Ansible (`portal_backend/register_gateway.yml`) ou manuellement :

```bash
curl -X POST https://mon.essensys.fr/api/portal/admin/gateways/register \
  -H "Authorization: Bearer <admin-jwt>" \
  -H "Content-Type: application/json" \
  -d '{"gateway_id":"gw-...","token":"...","machine_id":19,"eth0_mac":"...","eth1_mac":"..."}'
```

## Logs

```bash
journalctl -u essensys-backend -f | grep -i cloud
docker logs essensys-backend 2>&1 | grep -i cloud
```

## Dépannage

| Symptôme | Cause probable |
|----------|----------------|
| 401 sur pending-actions | Token ou MAC incorrects |
| Aucune action reçue | `machine_id` cloud ≠ actions en file PG |
| Sortie via eth1 | Vérifier route par défaut sur eth0 (`ip route get $(dig +short mon.essensys.fr)`) |
| HTTP dans les logs | Mettre à jour binaire / config `hub_url` |
| Runs `failed` pull busy | Plusieurs profils dus — un seul pull à la fois ; relancer Sync now |
| `[sync-alert] CRITICAL` | 3 échecs consécutifs sur un profil — voir admin Sync Cloud |

## Tests

```bash
# Depuis la gateway
./scripts/test-wan-https-ovh.sh https://mon.essensys.fr

# E2E scénarios LAN
cd essensys-server-backend/test && ./test_scenarios_e2e.sh

# Parité cloud (JWT requis)
EMAIL=... JWT_SECRET=... ./test_scenarios_cloud_parity.sh

# E2E inject (utilisateur avec portal_access)
# essensys-user-portal-frontend/test/e2e_user_portal.sh
# essensys-user-portal-frontend/test/e2e_scenarios_portal.sh
```

## Voir aussi

- [Portail remote](../acces/portal-remote.md)
- [Dépannage](troubleshooting.md)
