# Ports utilisés

Tableau récapitulatif des ports utilisés par les services Essensys.

| Service | Port | Protocole | Description |
|---------|------|-----------|-------------|
| Nginx | 80 | TCP | Frontend local + API locales |
| Nginx | 9090 | TCP | Frontend interne (Traefik) |
| Backend Go | 7070 | TCP | API backend |
| Traefik | 443 | TCP | Frontend WAN HTTPS |
| Traefik | 8080 | TCP | Dashboard Traefik |
| Traefik | 8081 | TCP | API interne Traefik |
| Traefik Block Service | 8082 | TCP | Service de blocage (403) |

## Conflits de ports

- Le port 80 est partagé entre Nginx (API locales) et Traefik (frontend local) grâce aux `server_name`
- Le port 443 est exclusivement utilisé par Traefik pour le WAN
- Le port 7070 est exclusivement utilisé par le backend Go

## Gateway CM5 (dual-NIC) : binding par interface

Sur la [Gateway CM5](../installation/gateway-cm5.md), chaque service est **lié à une
interface précise** (`network_mode: host`). Mappage réel observé via `ss -tlnp` :

| Service | Écoute | Interface | Rôle |
|---------|--------|-----------|------|
| Traefik | `<eth0>:443` | eth0 (LAN) | Frontend HTTPS utilisateurs |
| Nginx | `<eth0>:80` | eth0 (LAN) | Frontend / API local |
| Nginx | `<eth1>:80` | eth1 (armoire) | API legacy `BP_MQX_ETH` |
| AdGuard Home | `<eth0>:53` | eth0 (LAN) | DNS + filtrage |
| AdGuard Home | `<eth0>:3000` | eth0 (LAN) | Console d'administration |
| dnsmasq | `<eth1>:53` | eth1 (armoire) | DNS + DHCP armoire |
| Prometheus | `:9092` | toutes | Métriques |
| Alertmanager | `:9093` / `:9094` | toutes | Alertes |
| Control-plane | `:9100` | toutes | Supervision |
| node-exporter | `:9101` | toutes | Métriques hôte |
| MQTT (Mosquitto) | `:1883` | toutes | Bus MQTT |
| MCP | `:8083` | toutes | Pilotage IA |

!!! note
    AdGuard (DNS, eth0) et dnsmasq (DNS, eth1) coexistent **sans conflit** sur le
    port 53 car chacun est strictement lié à son interface (`bind-interfaces`).
