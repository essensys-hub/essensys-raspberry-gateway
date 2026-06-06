# Prompt : déploiement Ansible « Gateway Essensys » (double attache réseau)

Tu es un ingénieur **Ansible + Linux réseau** (Debian / Raspberry Pi OS). Ta mission est de **concevoir et implémenter** (ou d’étendre) un déploiement Ansible pour une **gateway matérielle Essensys**, en t’appuyant sur le playbook existant  
`essensys-ansible/install.raspberrypi.yml` (rôles, variables, structure `data_dir` / `config_dir`, utilisateur `essensys`, stack Docker `network_mode: host`, Nginx, Traefik, AdGuard, etc.).

Respecte les principes d’architecture logicielle : **séparation des préoccupations** (rôle dédié « réseau gateway » vs rôles applicatifs inchangés quand c’est possible), **variables explicites** (pas de magie), **idempotence**, et **réutilisation** des templates existants (Nginx, Traefik, AdGuard) plutôt que duplication inutile.

---

## 1. Contexte produit

- **eth0** : interface **vers le réseau local** (LAN administrateur / Internet selon l’installation). Les **utilisateurs** doivent accéder au **front en HTTPS** depuis ce LAN (via Traefik / certificats, comme aujourd’hui sur le port **443** du playbook actuel).
- **eth1** : interface **vers l’armoire Essensys** (réseau **privé**, isolé du LAN utilisateur). Sur ce segment :
  - la gateway doit **servir le DHCP** (baux pour l’armoire et équipements du bus privé) ;
  - le trafic « armoire → `mon.essensys.fr` » doit **revenir sur la gateway** pour l’**écoute applicative** attendue par le firmware (compatibilité **client legacy BP_MQX_ETH** : **port 80** côté armoire, contrainte documentée dans `essensys-ansible/docs/` — ne pas casser le mode single-packet TCP / Nginx actuel).

> Clarification port « HTTPS » : le firmware historique parle d’**HTTP sur le port 80** pour les API ; le **front utilisateur** reste en **TLS sur 443** (Traefik). Si le besoin métier impose du TLS sur 80 pour l’armoire, **le justifier** et proposer une variante ; sinon **aligner** sur le comportement documenté (80 = point d’entrée armoire / API, 443 = front WAN/LAN selon routage).

---

## 2. Exigences réseau (obligatoires)

| Interface | Rôle | Exigences |
|-----------|------|-----------|
| **eth0** | LAN | Accès **HTTPS** au frontend pour les opérateurs / utilisateurs du LAN. Pas d’exposition inutile des services « armoire uniquement » sur les adresses publiques du LAN si évitable. |
| **eth1** | Segment armoire | **Réseau IPv4 privé dédié** (choisir un RFC1918 cohérent, ex. `10.x.y.0/24`), **IP statique** sur la gateway pour eth1, **serveur DHCP** actif **uniquement** sur eth1 (ou sur ce sous-réseau), **pas de conflit** avec le DHCP du LAN sur eth0. |
| **DNS** | Résolution `mon.essensys.fr` | Sur le segment **eth1**, `mon.essensys.fr` doit résoudre vers l’**IP de la gateway vue depuis l’armoire** (typiquement l’IP eth1), pour que les requêtes HTTP(S) visent la gateway. Sur eth0/LAN, le comportement peut rester celui du DNS upstream / AdGuard existant, ou une règle explicite — **documenter** le choix (split DNS / réécriture AdGuard / fichier hosts interne). |
| **Écoute services** | Séparation | Les **flux armoire** (Nginx **:80** / API, contraintes legacy) doivent être **orientés / bindés** de façon à ne **servir le profil « armoire » que sur le contexte eth1** (adresse IP eth1 ou politique équivalente compatible `network_mode: host`). Le **443** Traefik pour le front doit être **accessible depuis eth0** (bind explicite `eth0_ip:443` si nécessaire pour éviter d’écouter sur eth1). |

Implémentation réseau attendue sur Pi OS bookworm : **systemd-networkd** ou **NetworkManager** ou **netplan** — **choisir une seule** voie cohérente avec l’OS cible, paquets disponibles, et intégration Ansible (`template` + `handlers` pour restart).

---

## 3. Plateforme CM5, NVMe et répartition stockage (obligatoire)

La gateway repose sur un **Raspberry Pi Compute Module 5 (CM5)** avec **eMMC interne** (`mmcblk0`) et un **SSD NVMe** (`nvme0n1`, typiquement en **PCIe** selon la carte porteuse / IO board). L’Ansible (ou une phase préalable documentée) doit couvrir :

### 3.1 Configuration CM5

- **Pré-requis matériel / firmware** : activer et valider ce qui est nécessaire pour le **NVMe** (PCIe, `BOOT_ORDER`, éventuels réglages EEPROM / `config.txt` / `cmdline.txt` selon la doc officielle Raspberry Pi pour CM5 + NVMe).
- **Réseau double carte** : s’assurer que **eth0 / eth1** sont bien reconnues (noms d’interface stables, pas de renommage aléatoire si possible : `systemd-networkd` `Match` par MAC ou `AlternativeNames`).
- **Documenter** toute étape **non automatisables** en Ansible pur (premier flash, choix du périphérique de boot, etc.) dans un court `README` du rôle « gateway hardware ».

### 3.2 NVMe (`nvme0n1`)

- **Partitionnement** et **système de fichiers** (ext4 ou autre choix justifié), **montage persistant** (`/etc/fstab` avec options adaptées aux SSD : `noatime` ou équivalent si pertinent).
- **Vérifications** : présence du périphérique, UUID stable, gestion d’erreur si NVMe absent (fail clair ou mode dégradé **documenté**).

### 3.3 Règle de placement des données

| Support | Périphérique cible | Contenu à y placer |
|---------|-------------------|---------------------|
| **Interne (système / source)** | **eMMC** `mmcblk0` | Système d’exploitation, **paquets**, arborescence **« source »** peu volatile : binaires installés par `apt`, code applicatif en lecture si applicable, **images de conteneurs** si la politique choisie est de les garder sur eMMC, fichiers de **configuration statique** légère, bootloader. |
| **NVMe (données vivantes)** | **`nvme0n1`** | **Tous les journaux** (`/var/log`, logs applicatifs Essensys, Traefik, Nginx, AdGuard, Prometheus, etc.), tout fichier ou répertoire **à forte écriture** ou **croissance** : bases/cache **Redis**, données **Prometheus TSDB**, **work** Docker (si utilisé), répertoires **`/opt/data`** du playbook Essensys (`data_dir`, logs sous `data_dir/logs`, caches, uploads temporaires), **swap** si activé, tout autre répertoire identifié comme « **qui bouge** » (write-heavy). |

- **Implémentation** : utiliser des **montages par bind** ou des **chemins configurés** dans les rôles existants (`data_dir`, `config_dir`, volumes Docker) pour que **`/opt/data`** et les logs système pointent vers des sous-répertoires sur **NVMe**, **sans** dupliquer inutilement l’OS sur le NVMe.
- **Ordre de boot** : les unités `systemd` / conteneurs doivent démarrer **après** `local-fs.target` sur le point de montage NVMe (dépendances explicites si besoin).
- **Alignement** : si les chemins par défaut du playbook (`data_dir: /opt/data`, etc.) changent, **mettre à jour** toutes les variables et templates concernés de façon **cohérente** (une seule source de vérité pour le préfixe NVMe, ex. `essensys_nvme_mount: /mnt/nvme` + sous-chemins).

---

## 4. Ancrage Ansible

- **Point d’entrée** : partir de `install.raspberrypi.yml` (liste des rôles et ordre).
- **Livrable minimal** :
  - soit un **nouveau playbook** du type `install.gateway.yml` qui inclut les mêmes rôles **avec** un rôle préalable ou intercalaire `raspberry_gateway_network` (nom indicatif) ;
  - soit des **variables de profil** `gateway_dual_nic: true` consommées par des rôles existants (`raspberry_common`, `raspberry_adguard`, `raspberry_nginx`, `raspberry_traefik`, `raspberry_compose`) **sans** mélanger la logique « profil gateway » dans des templates génériques de façon illisible — préférer des templates conditionnels (`{% if gateway_dual_nic %}`) **clairs** et testables.

- **Ne pas** casser le déploiement « Raspberry standard mono-interface » : le comportement actuel doit rester le défaut quand le profil gateway est désactivé.

---

## 5. Livrables attendus de ta réponse / de ton implémentation

1. **Schéma logique** (texte ou mermaid) : flux eth0 vs eth1, DHCP, DNS, ports 80/443.
2. **Fichiers Ansible** : playbook, rôle(s), `defaults/main.yml`, `tasks/main.yml`, `templates/` (unités systemd-networkd ou équivalent), **handlers**.
3. **Modifications ciblées** des templates **Nginx** / **Traefik** / **AdGuard** pour :
   - `listen` / `entryPoints` **par adresse** si `network_mode: host` ;
   - réécriture DNS **mon.essensys.fr → IP eth1** pour les clients du segment armoire.
4. **Variables documentées** (exemples) : plage DHCP, IP gateway eth1, domaine, flags profil.
5. **Checklist de validation** sur matériel réel : `ip a`, `ss -tlnp`, test `curl` depuis LAN (443) et depuis segment armoire (80 + résolution DNS), non-régression backend/MQTT/Redis si présents.
6. **Stockage** : procédure + tâches Ansible pour CM5/NVMe ; tableau des **bind mounts** ou chemins ; commandes de contrôle (`lsblk`, `findmnt`, `df -h`, croissance sur `nvme0n1` vs `mmcblk0`).

---

## 6. Sécurité et opérations

- eth1 = **réseau d’équipement** : limiter les services exposés sur cette IP au strict nécessaire (API armoire + ce qui est imposé par le produit).
- eth0 = **surface utilisateur** : HTTPS, mises à jour, SSH admin selon politique existante.
- Journaliser les changements réseau et prévoir un **rollback** (sauvegarde des fichiers réseau avant remplacement).

---

## 7. Critères d’acceptation

- [ ] eth0 obtient une connectivité LAN habituelle ; utilisateurs joignent le **front en HTTPS** (443) comme attendu.
- [ ] eth1 a une IP fixe sur un **réseau privé** ; **DHCP actif** uniquement pour ce lien / ce sous-réseau.
- [ ] Depuis l’armoire sur eth1, **`mon.essensys.fr`** résout vers la gateway et le **trafic applicatif** atteint les bons listeners (80 pour le chemin armoire / legacy, sans casser BP_MQX_ETH).
- [ ] Les listeners **80 (profil armoire)** ne remplacent pas indûment l’accès LAN sur eth0 si la politique est le cloisonnement — **respecter** la séparation demandée (armoire = eth1, utilisateurs = eth0).
- [ ] Déploiement **idempotent** et **documenté** (README court dans le rôle ou commentaire en tête de playbook).
- [ ] **CM5** correctement paramétrée pour le profil gateway (NVMe + double NIC) selon la documentation officielle.
- [ ] **`nvme0n1`** partitionné, monté, persistant au boot ; **logs et données à forte écriture** résident sur le NVMe ; **système et sources « stables »** restent sur **`mmcblk0`** (eMMC interne).
- [ ] Aucune saturation prématurée de l’eMMC par les logs ou bases métier : **vérification** post-install (I/O et espace disque).

---

## 8. Références à lire dans le dépôt avant de coder

- `essensys-ansible/install.raspberrypi.yml`
- `essensys-ansible/roles/raspberry_compose/templates/docker-compose.yml.j2` (`network_mode: host`)
- `essensys-ansible/roles/raspberry_nginx/templates/default.conf.j2` (+ doc `essensys-ansible/docs/nginx-vs-caddy.md`, `verification-configuration-ports.md`)
- `essensys-ansible/roles/raspberry_traefik/templates/traefik.yml.j2`
- `essensys-ansible/roles/raspberry_adguard/` (DHCP / DNS si réutilisation)

À la fin, résume les **fichiers créés ou modifiés** et les **risques résiduels** (ex. certificats TLS pour un hostname résolu uniquement en privé).
