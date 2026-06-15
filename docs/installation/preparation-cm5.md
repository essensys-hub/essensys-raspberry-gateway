# Préparation matérielle — Gateway CM5

## Matériel

- [ ] **Carte Essensys Gateway CM5** (stack 3 PCB + CM5)
- [ ] **Compute Module 5** (4 Go minimum recommandé)
- [ ] **NVMe M.2** (2230/2242) — données applicatives (`/mnt/nvme`)
- [ ] **Alimentation 12–24 V DC** (bornier industriel)
- [ ] **2 câbles Ethernet** (eth0 → routeur LAN, eth1 → armoire)
- [ ] **Montage DIN rail** (enclosure fournie)

Schémas KiCad : `src/cm5/` dans ce dépôt.

## Avant le premier boot

### 1. Activer PCIe / NVMe (firmware CM5)

Le NVMe doit être activé dans l'EEPROM Raspberry Pi (CM5). Sans cette étape, `nvme0n1` n'apparaît pas.

Voir la [documentation officielle Raspberry Pi CM5 + NVMe](https://www.raspberrypi.com/documentation/computers/compute-module.html).

### 2. Partition NVMe

```bash
sudo parted /dev/nvme0n1 -- mklabel gpt
sudo parted /dev/nvme0n1 -- mkpart essensys-data ext4 1MiB 100%
sudo mkfs.ext4 -L essensys-data /dev/nvme0n1p1
```

### 3. Relever les adresses MAC

```bash
ip link show eth0 | awk '/ether/{print $2}'   # -> gateway_eth0_mac (LAN)
ip link show eth1 | awk '/ether/{print $2}'   # -> gateway_eth1_mac (armoire)
```

Ces MAC sont **obligatoires** dans `inventory.gateway` pour un binding stable des interfaces.

## Stockage

| Support | Rôle |
|---------|------|
| **eMMC** (`mmcblk0`) | OS Debian ou NixOS, images Docker, config |
| **NVMe** (`/mnt/nvme`) | Redis, logs, Prometheus, données à forte écriture |

## Câblage réseau

| Port | Branchement |
|------|-------------|
| **eth0** (natif CM5) | Routeur / box Internet (DHCP) |
| **eth1** (USB RTL8153) | Switch ou bus armoire Essensys uniquement |

!!! danger "Ne pas inverser eth0/eth1"
    eth1 n'a **pas** de route par défaut. L'armoire ne doit jamais être branchée sur eth0.

## Suite

- [Installation OS Debian](os-installation.md)
- [Gateway CM5 — guide complet](gateway-cm5.md)
