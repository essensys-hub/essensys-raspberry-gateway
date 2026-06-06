# Prompt : déploiement NixOS « Gateway Essensys » (CM5, dual-NIC, stack complète)

Tu es un ingénieur **NixOS / Nix Flakes / Linux réseau ARM64**. Ta mission est de **concevoir et implémenter** sur la branche **`nixos`** du dépôt `essensys-raspberry-gateway` une configuration **déclarative et reproductible** remplaçant (ou parallélisant) le déploiement Ansible actuel (`essensys-ansible/install.raspberrypi.yml` / `install.gateway.yml`), pour la **gateway matérielle CM5** avec **double Ethernet**, **NVMe**, **front**, **back** et **Nginx Essensys**.

Respecte les principes d’architecture : **modules NixOS à responsabilité unique**, **options typées**, **flake comme point d’entrée**, **pas de logique métier dans `configuration.nix` monolithique**, réutilisation des configs existantes (`essensys-nginx`, design dual-NIC dans `openspec/changes/essensys-gateway-dual-nic/`).

---

## 0. Faisabilité CM5 + NixOS (réponse attendue dans ta livraison)

**Oui, c’est possible, mais pas « officiel » ni trivial aujourd’hui.**

| Aspect | État | Implication pour Essensys |
|--------|------|---------------------------|
| Support NixOS « upstream » Pi 5 / CM5 | **Non officiel** ; dépend du mainline Linux + U-Boot (position NixOS/nixpkgs) | Ne pas supposer une image SD « plug-and-play » comme sur Pi 4 |
| CM5 ≈ Pi 5 (BCM2712) | Même SoC, eMMC interne, PCIe NVMe | Les guides **Pi 5** s’appliquent en grande partie ; adapter DT / firmware CM5 IO board |
| Solutions communautaires | Flakes **`nixos-raspberrypi`** (nvmd), **rpi5-uefi**, wiki [NixOS on ARM/Raspberry Pi 5](https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi_5) | **Recommandé** : s’appuyer sur un flake éprouvé + kernel vendor ou `linuxPackages_rpi4` (unstable) |
| Double NIC (eth0 natif + eth1 USB RTL8153) | Généralement OK sous kernel vendor / DT | Nommer les interfaces par **MAC** (`systemd-networkd` `Match`) — la carte Essensys utilise un bridge USB pour eth1 |
| NVMe PCIe | Supporté avec firmware / DT corrects | Déclarer partitions et mounts dans NixOS (`fileSystems`, `boot.initrd`) |
| Headless (pas de GUI) | Avantage : pas de contrainte Wayland/GPU pour le produit | Privilégier profil **minimal headless** |

**Conclusion produit** : viser un **flake NixOS dédié gateway** sur branche `nixos`, avec **pinning** explicite du flake/kernel communautaire, **CI de build** (`nix build`) et **doc d’install** pour la première flash CM5. Traiter le chemin Ansible (branche `main` / prompt `Gateway.md`) et NixOS (`nixos`) comme **deux profils de déploiement** jusqu’à convergence.

---

## 1. Contexte et périmètre

### 1.1 Matériel cible (Essensys Gateway CM5)

- **CM5** : eMMC `mmcblk0` (OS / Nix store « stable » / configs)
- **NVMe** `nvme0n1` : logs, `data_dir`, Redis, Prometheus, données à forte écriture (cf. `prompts/Gateway.md` §3)
- **eth0** : LAN utilisateurs → **HTTPS front** (port **443**, Traefik ou équivalent NixOS)
- **eth1** : segment armoire privé → **DHCP**, **DNS split** (`mon.essensys.fr` → IP eth1), **HTTP :80** pour firmware **BP_MQX_ETH**

### 1.2 Références obligatoires

- `essensys-raspberry-gateway/prompts/Gateway.md` — exigences Ansible à **reproduire fonctionnellement**
- `essensys-raspberry-gateway/openspec/changes/essensys-gateway-dual-nic/design.md` — décisions réseau (systemd-networkd, dnsmasq eth1, bind ports)
- `essensys-nginx/` — config Nginx actuelle (`nginx.conf`, `conf.d/default.conf`, `Dockerfile`)
- `essensys-ansible/roles/raspberry_nginx/templates/default.conf.j2` — **profil gateway** + contraintes **single-packet TCP** API legacy
- Stack applicative actuelle : backend Go (`7070`), MCP (`8083`), control-plane (`9100`), frontend statique, Traefik (`443`), Redis, Mosquitto, AdGuard (LAN), Prometheus — tels que décrits dans `install.raspberrypi.yml`

### 1.3 Objectif `essensys-nginx` sous NixOS

**Ne pas se limiter à « docker run essensys-nginx »** sans analyse. Proposer et implémenter la **meilleure option Nix-native** :

| Option | Quand la choisir |
|--------|------------------|
| **A. `services.nginx`** avec config dérivée de `essensys-nginx` + overrides gateway | **Préféré** : moins de layers, bind IP explicite, tuning proxy_buffering natif |
| **B. `virtualisation.oci-containers` / `services.docker`** image `essensyshub/essensys-nginx` | Parité rapide avec prod Docker ; `networkMode = "host"` |
| **C. Package Nix custom** embarquant les mêmes fichiers que le repo `essensys-nginx` | Reproductibilité + tests `nginx -t` en build |

Le livrable doit inclure un **module NixOS** `essensys.services.nginx` (nom indicatif) consommant les mêmes sémantiques que le template Jinja gateway (listen eth1:80, reject eth0:80, proxy `/api/` vers backend, compat BP_MQX_ETH).

---

## 2. Structure de la branche `nixos` (à créer / compléter)

Travailler **exclusivement** sur la branche **`nixos`** de `essensys-raspberry-gateway` :

```text
essensys-raspberry-gateway/          # branche nixos
├── flake.nix                        # entrypoint : nixosConfigurations.gateway-cm5
├── flake.lock
├── nix/
│   ├── hosts/
│   │   └── gateway-cm5/
│   │       ├── default.nix            # assemble modules
│   │       └── hardware.nix           # CM5, DT, kernel, initrd modules nvme
│   ├── modules/
│   │   ├── essensys/
│   │   │   ├── nginx.nix              # ← port essensys-nginx + dual-NIC
│   │   │   ├── backend.nix
│   │   │   ├── frontend.nix
│   │   │   ├── traefik.nix
│   │   │   ├── redis.nix
│   │   │   ├── mosquitto.nix
│   │   │   └── monitoring.nix
│   │   ├── gateway/
│   │   │   ├── dual-nic.nix           # systemd-networkd eth0/eth1
│   │   │   ├── dnsmasq-armoire.nix    # DHCP + DNS eth1
│   │   │   └── nvme-layout.nix        # mounts + /opt/data sur nvme0n1
│   │   └── platform/
│   │       └── cm5-rpi5.nix           # boot, kernel flake pin, UEFI/DT
│   ├── packages/
│   │   └── essensys-nginx-config/     # fetch/copy depuis essensys-nginx repo
│   └── overlays/                      # si patches nixpkgs nécessaires
├── prompts/
│   ├── Gateway.md                     # profil Ansible (référence)
│   └── NixOS.md                       # ce prompt
└── docs/
    └── nixos-install-cm5.md           # procédure flash + deploy
```

**Règle** : la branche `main` reste hardware + openspec + prompts ; la branche `nixos` porte **tout le flake** et la doc d’installation NixOS.

---

## 3. Exigences fonctionnelles (parité avec Gateway Ansible)

### 3.1 Réseau dual-NIC

- **eth0** : client DHCP ou statique (LAN) ; exposer **443** pour le front utilisateur
- **eth1** : IP statique RFC1918 ; **dnsmasq** `interface=eth1` uniquement ; **pas de DHCP** sur eth0
- **DNS split** : sur eth1, `mon.essensys.fr` → IP eth1 gateway
- Interfaces stables : `Match` par adresse MAC dans `systemd.network` units générées par Nix

Implémentation NixOS : `networking.useNetworkd = true`, `systemd.network.networks`, `services.dnsmasq` (ou module custom) — **documenter** conflit éventuel port 53 avec AdGuard sur eth0 et la mitigation (bind-address).

### 3.2 Nginx (`essensys-nginx`)

Reproduire depuis `essensys-ansible/roles/raspberry_nginx/templates/default.conf.j2` :

- `listen {{ eth1_ip }}:80` — serveur armoire + API + front local segment privé
- `listen {{ eth0_ip }}:80` → `return 444` (rejeter HTTP LAN sur eth0 en profil gateway)
- `/api/` → `127.0.0.1:7070` avec **proxy_buffering**, **gzip off**, tailles buffer — **BP_MQX_ETH**
- `/mcp/`, `/admin/` (control-plane), assets statiques `/var/www/html`
- Logs vers chemin NVMe

Options NixOS exposées : `services.essensys.nginx.enable`, `armoireListenAddress`, `backendPort`, `frontendRoot`, etc.

### 3.3 Front / Back / edge

| Composant | Rôle | Port / bind attendu |
|-----------|------|---------------------|
| **Frontend** (React build) | SPA servie par Nginx ou Traefik | Fichiers statiques ; utilisateurs LAN via **HTTPS 443** |
| **Backend Go** | API `/api/` | `127.0.0.1:7070` |
| **Traefik** | TLS Let's Encrypt, front WAN/LAN | **`eth0_ip:443`** en profil gateway |
| **Redis / Mosquitto** | bus interne | localhost / data NVMe |
| **AdGuard** (optionnel LAN) | DNS eth0 | ne pas écouter sur eth1 si dnsmasq y est |

Décider pour chaque service : **package Nix natif** vs **OCI** vs **systemd + binaire compilé** (backend Go). Justifier dans `design.md` NixOS.

### 3.4 Stockage CM5 + NVMe

- **eMMC** : `/`, `/nix/store`, configs, binaires
- **NVMe** : `/var/log`, `/opt/data` (ou bind), Redis, Prometheus TSDB
- Déclarer dans Nix : `fileSystems."/mnt/nvme"`, `systemd.tmpfiles`, permissions user `essensys`

---

## 4. Stratégie de déploiement NixOS (comment « tout déployer »)

### 4.1 Bootstrap (première installation CM5)

Documenter une procédure en **phases** :

1. **Firmware** : activer PCIe/NVMe sur CM5 (EEPROM / config firmware — hors Nix, une fois)
2. **Image installer** : construire ou télécharger une image depuis le flake (`nix build .#installerImages` si basé sur `nixos-raspberrypi`, ou SD UEFI + minimal ISO aarch64)
3. **Install** : partitionner eMMC + NVMe, `nixos-install --flake .#gateway-cm5`, copier firmware Pi si nécessaire
4. **Deploy** : depuis poste de dev :  
   `nixos-rebuild switch --flake .#gateway-cm5 --target-host root@<eth0-ip>`
5. **Secrets** : `agenix`, `sops-nix`, ou fichiers hors git pour ACME email, tokens — **ne jamais** committer de secrets

### 4.2 Mises à jour

- `nixos-rebuild switch` idempotent
- Pinning `flake.lock` + channel/tag nixpkgs
- Option : **Colmena** ou **deploy-rs** pour flotte future

### 4.3 Intégration repo `essensys-nginx`

- **Source de vérité** : le repo `essensys-nginx` reste le référentiel des fichiers `.conf`
- Dans le flake : `src = fetchFromGitHub { owner = "…"; repo = "essensys-nginx"; rev = "…"; };` ou submodule/path local en dev
- Pipeline : toute modification `essensys-nginx` → bump rev dans flake → rebuild nginx config store path
- Envisager une branche **`nixos`** ou tag dans `essensys-nginx` si des templates `.nix` y vivent (optionnel ; préférer module dans `essensys-raspberry-gateway/nix/`)

---

## 5. Livrables attendus

1. **Branche `nixos`** créée avec flake minimal **compilable** (`nix flake check`)
2. **Note de faisabilité CM5** (1 page) : kernel, UEFI/DT, risques eth1 USB, NVMe
3. **Module `essensys-nginx`** NixOS aligné sur profil dual-NIC + BP_MQX_ETH
4. **Modules gateway** : dual-nic, dnsmasq, nvme-layout
5. **Esquisse modules** backend / frontend / traefik (même si certains en stub avec TODO)
6. **`docs/nixos-install-cm5.md`** : flash, rebuild, validation
7. **Matrice de parité** Ansible ↔ NixOS (tableau critères d’acceptation)
8. **Checklist validation matérielle** :
   - `ip a`, `networkctl status`
   - `ss -tlnp` — 443 sur eth0, 80 sur eth1 seulement
   - `curl -k https://<eth0>/` (front)
   - depuis segment armoire : `nslookup mon.essensys.fr`, `curl http://mon.essensys.fr/api/...`
   - `findmnt`, `df -h` — logs/data sur NVMe

---

## 6. Critères d’acceptation

- [ ] Branche **`nixos`** existe dans `essensys-raspberry-gateway` avec flake et structure `nix/` décrite
- [ ] **`nix build .#nixosConfigurations.gateway-cm5.config.system.build.toplevel`** réussit (native ou cross avec `--system aarch64-linux`)
- [ ] Config Nginx **équivalente** au profil gateway Ansible + contraintes `essensys-nginx` / BP_MQX_ETH
- [ ] Dual-NIC, DHCP eth1, DNS `mon.essensys.fr`, séparation 80/443 documentée en Nix
- [ ] Layout stockage eMMC vs NVMe déclaré
- [ ] Chemin de déploiement **`nixos-rebuild switch --flake`** documenté de bout en bout
- [ ] Branche `main` / déploiement Ansible **non régressé** (NixOS = opt-in branche séparée)

---

## 7. Risques et décisions ouvertes (à trancher dans ta livraison)

| Sujet | Question |
|-------|----------|
| Kernel | Vendor flake vs `linuxPackages_rpi4` — perf, support RTL8153 eth1 |
| Docker vs natif | Garder parité Docker Compose ou migrer services en systemd Nix ? |
| AdGuard | Package Nix disponible ? Alternative `services.unbound` + blocklists ? |
| Certificats | ACME HTTP-01 sur eth0 vs DNS-01 pour `mon.essensys.fr` privé |
| CI | GitHub Actions `nix build` cache substituter pour aarch64 |

---

## 8. Commandes de démarrage (pour l’agent implémenteur)

```bash
cd essensys-raspberry-gateway
git checkout -b nixos    # si la branche n’existe pas encore
# créer flake.nix + nix/… selon structure §2
nix flake init -t github:nixos-raspberrypi/nixos-raspberrypi  # point de départ possible, à adapter CM5
nix build .#nixosConfigurations.gateway-cm5.config.system.build.toplevel
```

À la fin, résumer : **faisabilité CM5**, **fichiers créés**, **écarts vs Ansible**, **prochaines étapes** (backend package, secrets, CI).
