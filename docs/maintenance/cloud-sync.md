# Cloud sync (agent portail distant)

Le module **`internal/cloudsync`** du backend gateway (`essensys-server-backend`) synchronise les actions du portail OVH vers la file locale Redis.

## Activation

`config.yaml` sur la gateway :

```yaml
cloud:
  enabled: true
  hub_url: "https://mon.essensys.fr"
  gateway_id: "gw-essensys-gateway"   # optionnel si dérivé de MAC
  gateway_token: "<token Ansible vault>"
  poll_interval_seconds: 30
```

!!! danger "HTTPS uniquement"
    `hub_url` doit être `https://mon.essensys.fr`. Aucun agent ne doit utiliser `http://` vers le hub WAN.

## Cycle de poll

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

## Tests

```bash
# Depuis la gateway
./scripts/test-wan-https-ovh.sh https://mon.essensys.fr

# E2E inject (utilisateur avec portal_access)
# essensys-user-portal-frontend/test/e2e_user_portal.sh
```

## Voir aussi

- [Portail remote](../acces/portal-remote.md)
- [Dépannage](troubleshooting.md)
