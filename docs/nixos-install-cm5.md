# Installation NixOS — Essensys Gateway CM5

Guide d’installation et de déploiement pour la branche **`nixos`** de `essensys-raspberry-gateway`.
Profil **dual-NIC** : eth0 (LAN / HTTPS utilisateurs), eth1 (armoire / DHCP / HTTP legacy).

Références : `prompts/NixOS.md`, OpenSpec `essensys-gateway-nixos`, parité Ansible `essensys-gateway-dual-nic`.

---

## 1. Prérequis matériels (hors Nix)

1. **CM5** montée sur la carte IO Essensys (dual Ethernet, NVMe M.2).
2. Activer **PCIe / NVMe** dans le firmware CM5 (EEPROM Raspberry Pi).
3. Vérifier :
   ```bash
   lsblk          # mmcblk0 (eMMC), nvme0n1 (SSD)
   ip link show   # noter MAC eth0 (natif) et eth1 (USB RTL8153)
   ```
4. Créer une partition ext4 sur NVMe, label **`essensys-nvme`** :
   ```bash
   sudo parted /dev/nvme0n1 -- mklabel gpt
   sudo parted /dev/nvme0n1 -- mkpart essensys-data ext4 1MiB 100%
   sudo mkfs.ext4 -L essensys-nvme /dev/nvme0n1p1
   ```

---

## 2. Prérequis poste de build

- [Nix](https://nixos.org/download.html) avec flakes :
  ```bash
  experimental-features = nix-command flakes
  ```
- Dépôt cloné, branche `nixos` :
  ```bash
  git clone …/essensys-raspberry-gateway
  cd essensys-raspberry-gateway
  git checkout nixos
  ```
- `essensys-nginx` en sibling (`../essensys-nginx`) ou override flake input.

---

## 3. Configuration hôte

Éditer `nix/hosts/gateway-cm5/default.nix` :

| Option | Description |
|--------|-------------|
| `gateway.eth0Mac` / `eth1Mac` | MAC réelles |
| `gateway.eth1Address` | IP statique armoire (ex. `10.0.1.1`) |
| `gateway.eth0Address` | IP LAN réservée si `bindStrict` + Traefik ; `null` = DHCP |
| `nvme.device` | `/dev/disk/by-label/essensys-data` (CM5 prod) |

---

## 4. Première installation

### Option A — `nixos-install` sur CM5 (aarch64)

```bash
# Sur la CM5 (ou via chroot depuis un live ISO aarch64)
nixos-install --flake .#gateway-cm5 --no-root-password
reboot
```

### Option B — image communautaire Pi 5

S’appuyer sur [NixOS on ARM/Raspberry Pi 5](https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi_5) ou le flake `nixos-raspberrypi`, puis :

```bash
nixos-rebuild switch --flake .#gateway-cm5
```

---

## 5. Déploiement à distance

Depuis le poste de développement :

```bash
nixos-rebuild switch --flake .#gateway-cm5 --target-host root@<eth0-ip>
```

Idempotent : relancer après chaque modification du flake.

---

## 6. Secrets (agenix / sops-nix)

**Ne pas** committer de secrets en clair.

Exemple avec **agenix** :

1. Ajouter l’input agenix au `flake.nix`.
2. Chiffrer `secrets/acme-email.age` pour la clé SSH de la gateway.
3. Référencer dans le module Traefik :
   ```nix
   services.essensys.traefik.acmeEmail = lib.removeSuffix "\n" (builtins.readFile config.age.secrets.acme-email.path);
   ```

Alternative : **sops-nix** avec fichier `secrets.yaml` chiffré.

Variables concernées : email ACME, tokens API, mots de passe Redis si exposé.

---

## 7. Checklist validation matérielle

```bash
# Réseau
ip a
networkctl status

# Ports (Nginx :80 eth1, Traefik :443 eth0)
ss -tlnp

# LAN — front HTTPS (Traefik activé)
curl -k https://<eth0_ip>/

# Segment armoire
dig @<eth1_ip> mon.essensys.fr +short    # → IP eth1
curl -v http://mon.essensys.fr/api/       # depuis bus armoire

# Stockage
findmnt /mnt/nvme
df -h /mnt/nvme/data /nix/store
```

Relancer `nixos-rebuild switch` une seconde fois pour confirmer l’idempotence.

---

## 8. Matrice de parité Ansible ↔ NixOS

| Capacité | Ansible (`essensys-gateway-dual-nic`) | NixOS (branche `nixos`) |
|----------|----------------------------------------|-------------------------|
| Dual NIC | `raspberry_gateway_network` | `nix/modules/gateway/dual-nic.nix` |
| DHCP eth1 | `raspberry_gateway_dhcp` (dnsmasq) | `gateway/dnsmasq-armoire.nix` |
| DNS armoire | dnsmasq `address=/mon.essensys.fr/…` | `gateway.armoireHostname` |
| NVMe | `raspberry_gateway_nvme` | `gateway/nvme-layout.nix` |
| Nginx armoire | `raspberry_nginx` template | `essensys/nginx.nix` |
| Traefik 443 eth0 | `raspberry_traefik` template | `essensys/traefik.nix` |
| Backend :7070 | Docker / systemd Ansible | `essensys/backend.nix` (OCI ou package) |
| Redis / MQTT | Docker compose | `essensys/redis.nix`, `mosquitto.nix` |
| Playbook | `install.gateway.yml` | `flake.nix` → `#gateway-cm5` |
| Déploiement | `ansible-playbook` | `nixos-rebuild switch --flake` |

---

## 9. Build local (sans matériel)

```bash
nix flake check
nix build .#nixosConfigurations.gateway-cm5.config.system.build.toplevel --system aarch64-linux
```

Cross-build depuis x86_64 :

```bash
nix build .#nixosConfigurations.gateway-cm5.config.system.build.toplevel \
  --system aarch64-linux \
  --extra-experimental-features 'nix-command flakes'
```

---

## 10. Dépannage

| Symptôme | Action |
|----------|--------|
| NVMe absent au boot | Firmware PCIe ; ou `services.essensys.nvme.required = false` (mode dégradé) |
| eth1 absent | Kernel / module USB ; vérifier RTL8153 |
| Conflit port 53 | dnsmasq bind eth1 uniquement ; AdGuard eth0 uniquement |
| BP_MQX_ETH API | Vérifier `proxy_buffering on`, `gzip off` dans config Nginx générée |

---

## 11. Ordre de démarrage réseau

Nginx et Traefik dépendent de `network-online.target`. Si eth0 est en DHCP et `bindStrict = true`, définir `eth0Address` sur l’IP réservée du routeur LAN ou utiliser `bindStrict = false` jusqu’à réservation DHCP fixe.
