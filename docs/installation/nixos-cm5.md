# Préparation et installation NixOS — Gateway CM5

Guide pour la branche **`nixos`** de `essensys-raspberry-gateway` : profil **dual-NIC** déclaratif (eth0 LAN/HTTPS, eth1 armoire/DHCP/HTTP legacy).

!!! info "Deux OS pour la même Gateway"
    **Production actuelle** : Debian 13 + Docker via [Gateway CM5 (dual-NIC)](gateway-cm5.md).
    **NixOS** : même réseau et même NVMe, configuration via flake Nix.

---

## Partie A — Préparation Ansible

| Playbook | Rôle | Usage |
|----------|------|--------|
| `uninstall.cm5.yml` | `raspberry_cm5_uninstall` | Retire stack Debian/Ansible/Docker |
| `prepare.nixos-cm5.yml` | `raspberry_cm5_nixos` | Clone flake, installe Nix, prépare eMMC/NVMe |

```bash
cd essensys-ansible

ansible-playbook uninstall.cm5.yml -i inventory.gateway \
  -e confirm_cm5_uninstall=true

ansible-playbook prepare.nixos-cm5.yml -i inventory.gateway \
  -e confirm_cm5_nixos_prep=true
```

Après `prepare` :

- Flake : `/opt/essensys-nixos`
- Hardware généré : `nix/hosts/gateway-cm5/hardware-cm5.generated.nix`
- Script eMMC : `/usr/local/sbin/essensys-prepare-nixos-mmc.sh`

!!! warning "Repartition eMMC"
    Ne pas repartitionner l'eMMC depuis le système qui boot dessus. Utiliser un media recovery, puis `nixos-install --flake /opt/essensys-nixos#gateway-cm5`.

---

## Partie B — Installation NixOS (flake)

### Prérequis poste de build

- [Nix](https://nixos.org/download.html) avec flakes (`experimental-features = nix-command flakes`)
- Dépôt cloné, branche `nixos`
- `essensys-nginx` en sibling ou via flake input

### Configuration hôte

Éditer `nix/hosts/gateway-cm5/default.nix` :

| Option | Description |
|--------|-------------|
| `gateway.eth0Mac` / `eth1Mac` | MAC réelles |
| `gateway.eth1Address` | IP statique armoire (ex. `10.0.1.1`) |
| `gateway.eth0Address` | IP LAN fixe si `bindStrict` ; `null` = DHCP |
| `nvme.device` | `/dev/disk/by-label/essensys-data` |

### Installation

```bash
# Sur la CM5
nixos-install --flake .#gateway-cm5 --no-root-password
reboot
```

Déploiement à distance :

```bash
nixos-rebuild switch --flake .#gateway-cm5 --target-host root@<eth0-ip>
```

### Secrets

Ne pas committer de secrets en clair. Utiliser **agenix** ou **sops-nix** (email ACME, tokens API, etc.).

---

## Checklist validation

```bash
ip -br addr show
ss -tlnp | grep -E ':80|:443|:53'
curl -k https://mon.essensys.local/
dig @10.0.1.1 mon.essensys.fr +short
findmnt /mnt/nvme
```

---

## Parité Ansible ↔ NixOS

| Capacité | Ansible | NixOS |
|----------|---------|-------|
| Dual NIC | `raspberry_gateway_network` | `gateway/dual-nic.nix` |
| DHCP eth1 | `raspberry_gateway_dhcp` | `gateway/dnsmasq-armoire.nix` |
| NVMe | `raspberry_gateway_nvme` | `gateway/nvme-layout.nix` |
| Nginx armoire | `raspberry_nginx` | `essensys/nginx.nix` |
| Traefik 443 | `raspberry_traefik` | `essensys/traefik.nix` |
| Déploiement | `install.gateway.yml` | `nixos-rebuild switch` |

---

## Dépannage

| Symptôme | Action |
|----------|--------|
| NVMe absent | Firmware PCIe ; ou mode dégradé sans NVMe |
| eth1 absent | Module USB RTL8153 |
| Conflit port 53 | dnsmasq sur eth1 uniquement ; AdGuard sur eth0 |
| API BP_MQX_ETH | `proxy_buffering on`, `gzip off` sur Nginx eth1 |

---

## Voir aussi

- `essensys-ansible/roles/raspberry_cm5_nixos/README.md`
- OpenSpec `essensys-gateway-nixos` dans ce dépôt
