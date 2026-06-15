# Versions du Système — Gateway CM5

Documentation alignée sur [essensys-raspberry-install](https://github.com/essensys-hub/essensys-raspberry-install/blob/main/docs/versions.md) ; entrées spécifiques gateway ci-dessous.

## Versions

| Version | Statut | Date | Description |
| :--- | :--- | :--- | :--- |
| **draft-remote** | **Brouillon** | Juin 2026 | Portail remote `mon.essensys.fr/portal/`, cloudsync HTTPS, doc gateway complète |
| **cloud-consolidated** | **Production OVH** | Juin 2026 | Hub unique `essensys-cloud-backend` :8080, OpenSpec phases 0–7 |
| V.1.2.2 | Dev | Jan 2026 | UniFi Protect, MCP ops |
| V.1.1.0 | Production legacy | Jan 2026 | Redis, stack Docker |

## Détails — cloud-consolidated (hub OVH unifié)

- **Backend** : `essensys-user-portal-backend` → service `essensys-cloud-backend` (:8080, `CONSOLIDATED_MODE=true`)
- **Legacy dual** : `essensys-backend` + `essensys-portal-backend` (:8081) — **arrêtés** en prod
- **Ansible** : rôle `cloud_backend`, flags `cloud_backend_consolidated` / `cloud_backend_legacy_mode`
- **Doc** : [Cloud backend consolidation](acces/cloud-backend-consolidation.md), [E2E](cloud-backend-consolidation-e2e.md)

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
