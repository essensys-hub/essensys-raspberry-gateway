# Introduction — Installation Gateway CM5

Cette section décrit le parcours d'installation de la **Gateway Essensys** (Compute Module 5, double RJ45).

[:material-play-circle: **Guide complet dual-NIC**](gateway-cm5.md){ .md-button .md-button--primary }

## Parcours recommandé

| Étape | Page | Description |
|-------|------|-------------|
| 1 | [Préparation CM5](preparation-cm5.md) | Matériel, NVMe, firmware PCIe |
| 2 | [OS Debian](os-installation.md) ou [NixOS](nixos-cm5.md) | Système sur eMMC |
| 3 | [Domaine WAN](wan.md) | DuckDNS / NAT (optionnel) |
| 4 | [Déploiement Ansible](essensys-installation.md) | `install.gateway.yml` |
| 5 | [Accès](acces/index.md) | Local, WAN, [portail remote](../acces/portal-remote.md) |

## Deux systèmes d'exploitation

| OS | Playbook / outil | Quand |
|----|------------------|-------|
| **Debian 13 + Docker** | `ansible-playbook install.gateway.yml` | Production actuelle |
| **NixOS** | `prepare.nixos-cm5.yml` puis `nixos-rebuild switch` | Variante déclarative (branche `nixos`) |

Les deux profils partagent le même modèle réseau : **eth0** = LAN/Internet, **eth1** = armoire `10.0.1.0/24`.

```bash
cd essensys-ansible
ansible-playbook install.gateway.yml -i inventory.gateway
```

## Inventaire

Variables clés dans `inventory.gateway` : `gateway_eth0_mac`, `gateway_eth1_mac`, `gateway_eth1_ip`, `gateway_armoire_hostname` (`mon.essensys.fr`), NVMe, cloud hub URL.

Voir [Gateway CM5 — section 6](gateway-cm5.md#6-deploiement) pour le détail.

## Raspberry Pi 4 (mono-interface)

Pour l'installation historique sur **Raspberry Pi 4** (un seul réseau), consultez
[essensys-raspberry-install](https://github.com/essensys-hub/essensys-raspberry-install/docs/installation/).
