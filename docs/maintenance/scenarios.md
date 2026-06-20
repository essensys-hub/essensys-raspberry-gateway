# Scénarios domotique (gateway CM5)

Page opérationnelle pour la gestion des scénarios mémorisés (OpenSpec **essensys-scenario-management**).

## Accès UI

| Contexte | URL |
|----------|-----|
| LAN | `https://mon.essensys.local/scenarios` |
| Portail OVH | `https://mon.essensys.fr/portal/scenarios` |

Réglages sync : **Paramètres → Synchronisation → Synchroniser les scénarios**.

## Déploiement OVH (portail)

1. Déployer `essensys-user-portal-backend` + frontends (Ansible `support-site.yml`).
2. Migration PostgreSQL **009** appliquée au démarrage (`MIGRATIONS_DIR`) — seed profil **Scénarios**.
3. Vérifier profil :

```bash
psql "$DATABASE_URL" -c "SELECT name, index_ranges, exclude_indices, enabled FROM sync_profiles WHERE name = 'Scénarios';"
```

4. Déployer gateway CM5 (backend + frontend) avec cloud sync activé.

## Déploiement gateway CM5

Ansible (`install-gateway.md`) — variables cloud inchangées ; profil scénarios activé par défaut en PG :

```yaml
cloud_sync_enabled: true
cloud_scheduled_sync_enabled: true
scenarios_sync_enabled: true   # défaut ; toggle UI si besoin
```

Rebuild backend :

```bash
cd essensys-server-backend && CGO_ENABLED=0 go build -o server ./cmd/server
```

## Tests pilote (Phase 6)

### LAN — CM5

```bash
cd essensys-server-backend/test
chmod +x test_scenarios_e2e.sh
./test_scenarios_e2e.sh
# BASE=http://192.168.x.x si test distant
```

Enchaînement manuel :

1. **Je sors** : bouton slot 2 ou `curl -X POST http://127.0.0.1/api/scenarios/2/launch`
2. **Perso 1** : éditer slot 6 dans l'UI, sauvegarder
3. **Sync** : activer toggle Réglages ; attendre run profil Scénarios (~3 h ou Sync now admin OVH)

### Parité cloud vs armoire

```bash
EMAIL=user@example.com JWT_SECRET=... ./test_scenarios_cloud_parity.sh
```

### Portail API

```bash
cd essensys-user-portal-frontend/test
EMAIL=... JWT_SECRET=... ./e2e_scenarios_portal.sh
```

## Dépannage

| Symptôme | Action |
|----------|--------|
| Profil Scénarios absent | Appliquer migration 009 ; redémarrer cloud-backend |
| Toggle grisé « Profil cloud indisponible » | Vérifier `cloud.enabled`, token gateway, poll sync-config |
| Push contient 590 | Vérifier `exclude_indices` sur profil ; rebuild backend ≥ V.1.4.0 |
| Portail ≠ LAN après sync | Attendre fin run ; `./test_scenarios_cloud_parity.sh` |
| Slot 1 non éditable | Normal — réservé serveur (Mode B) |

## Voir aussi

- [Cloud sync](cloud-sync.md)
- [Portail remote](../acces/portal-remote.md)
- Wiki : `essensys-memory/wiki/concepts/scenarios-domotique.md`
