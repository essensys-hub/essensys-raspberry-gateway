# Versions du Système — Gateway CM5

Documentation alignée sur [essensys-raspberry-install](https://github.com/essensys-hub/essensys-raspberry-install/blob/main/docs/versions.md) ; entrées spécifiques gateway ci-dessous.

## Versions

| Version | Statut | Date | Description |
| :--- | :--- | :--- | :--- |
| **V.1.4.0** | **Pilote** | Juin 2026 | Gestion scénarios (UI, API, sync cloud 591–919) |
| **V.1.3.1** | **Pilote** | Juin 2026 | Sync cloud scheduler (profils 3 h, pull/push planifié) |
| **draft-remote** | **Brouillon** | Juin 2026 | Portail remote `mon.essensys.fr/portal/`, cloudsync HTTPS, doc gateway complète |
| V.1.2.2 | Dev | Jan 2026 | UniFi Protect, MCP ops |
| V.1.1.0 | Production legacy | Jan 2026 | Redis, stack Docker |

## Détails — V.1.4.0 (scénarios domotique)

- **UI** : page `/scenarios` — boutons Je sors / vacances / Perso, éditeur drawer (lumières, volets, avancé)
- **API LAN** : `GET/PUT/POST /api/scenarios/*`, `GET /api/scenarios/meta/bitmasks`
- **API portail** : parité `/api/portal/scenarios/*` sur `mon.essensys.fr`
- **Mode A** : lancement slot `{590: "2..8"}` sans bloc 605–622
- **Mode B** : inchangé pour actions immédiates (`590=1` + 605–622)
- **Sync cloud** : profil PostgreSQL **Scénarios** (591–919, `exclude_indices: [590]`, 3 h)
- **Réglages** : toggle « Synchroniser les scénarios » → `PUT /api/admin/scenarios/sync`
- **Tests E2E** : `essensys-server-backend/test/test_scenarios_e2e.sh`, `test_scenarios_cloud_parity.sh`

> Voir [Scénarios](maintenance/scenarios.md) et OpenSpec `essensys-scenario-management`.

## Détails — V.1.3.1 (sync cloud scheduler)

- **Scheduler** : `internal/cloudsync` poll `GET /api/gateway/sync-config`, exécute profils PostgreSQL (défaut **3 h**)
- **Pull** : `ExchangePullScheduler` — rotation serverinfos ≤30 indices/cycle firmware
- **Push** : `POST /api/gateway/exchange` merge OVH ; fallback `exchangePushIndices()` si pas de profils
- **LAN admin** : `GET /api/admin/cloudsync/status`, sync manuelle `/api/admin/heating/sync`
- **UI locale** : Paramètres → Synchronisation ; Chauffage → Sync armoire
- **Config** : `cloud.scheduled_sync_enabled: true` (Ansible `cloud_scheduled_sync_enabled`)
- **Build CM5** : `CGO_ENABLED=0 go build` (binaire statique pour image Alpine)

> Voir [Cloud sync](maintenance/cloud-sync.md) et OpenSpec `essensys-cloud-sync-scheduler`.

## Détails — draft-remote (portail + gateway)

- **Portail distant** : UI copiée depuis `essensys-server-frontend`, API `essensys-user-portal-backend` sur OVH
- **Cloud sync** : poll HTTPS `mon.essensys.fr`, expansion ordres 590+605..622
- **Sécurité dual-NIC** : eth1 armoire isolée, eth0 seul accès Internet
- **Documentation** : site MkDocs `essensys-raspberry-gateway/docs` (miroir structure raspberry-install)

> Voir [Portail remote](acces/portal-remote.md) et [Cloud sync](maintenance/cloud-sync.md).

## Détails de la Version V.1.2.2 (UniFi Protect)

La version V.1.2.2 ajoute l'intégration UniFi Protect pour l'affichage des caméras.

### Nouveautés majeures :
*   **Intégration UniFi Protect** : Affichage des caméras UniFi (notamment Sonnet) sur le dashboard principal et page dédiée.
*   **Proxy API UniFi** : Le backend fait office de proxy sécurisé vers l'API UniFi Protect.
*   **Snapshots en temps réel** : Rafraîchissement automatique des images des caméras toutes les 10-15 secondes.
*   **Interface utilisateur** : Nouvelle page "UniFi Protect" avec filtres et grille responsive.
*   **Documentation MCP** : Ajout d'un guide opérationnel MCP avec outils actifs, exemples de commandes et texte prêt pour intégration OpenClaw (`docs/maintenance/mcp.md`).
*   **MCP Ops** : Ajout d'outils de diagnostic/réparation (`list_service_status`, `read_service_logs`, `restart_service`, `get_port_diagnostics`, `get_system_metrics`, `run_self_diagnostic`).
*   **CM5 Ansible** : Rôles `raspberry_cm5_uninstall` et `raspberry_cm5_nixos` + playbooks `uninstall.cm5.yml` / `prepare.nixos-cm5.yml` (doc `docs/installation/nixos-cm5.md`).

> [!NOTE]
> Cette version nécessite un UniFi Dream Machine Pro (UDM Pro) accessible via HTTPS. La configuration se fait dans `config.yaml` du backend.

## Détails de la Version V.1.1.0 (Redis)

La version V.1.1.0 est la nouvelle référence pour la production.

### Nouveautés majeures :
*   **Persistance Redis** : Les états (lumières, volets, etc.) sont sauvegardés même en cas de redémarrage du backend.
*   **Historique des Actions** : La file d'attente globale est gérée par Redis, assurant qu'aucun ordre n'est perdu.
*   **Performance** : Traitement asynchrone amélioré grâce à la structure de données Redis.

> [!NOTE]
> Cette version nécessite `redis-server` installé sur le Raspberry Pi. Les scripts d'installation gèrent cela automatiquement.
