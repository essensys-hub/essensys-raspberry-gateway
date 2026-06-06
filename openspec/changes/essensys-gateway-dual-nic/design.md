## Context

The target hardware is a **Raspberry Pi Compute Module 5 (CM5)** running **Raspberry Pi OS Bookworm (Debian 12)**, fitted with:
- **eMMC** (`mmcblk0`): OS, packages, static config, optionally container images.
- **NVMe SSD** (`nvme0n1`, PCIe): logs, TSDB, caches, `data_dir` write-heavy paths.
- **Two Ethernet interfaces** (`eth0` = LAN/WAN, `eth1` = private armoire bus).

The existing Ansible entrypoint is `essensys-ansible/install.raspberrypi.yml`, which chains roles: `raspberry_common` → `raspberry_adguard` → `raspberry_nginx` → `raspberry_traefik` → `raspberry_compose`. All Docker services run with `network_mode: host`, so port binding is controlled by application config (listen address), not by Docker NAT.

The legacy armoire firmware (`BP_MQX_ETH`) speaks plain HTTP on port 80 to the hostname `mon.essensys.fr`. This constraint is documented and **must not be broken**.

## Goals / Non-Goals

**Goals:**
- Stable, idempotent dual-NIC network configuration (eth0 DHCP client, eth1 static IP on a private RFC1918 subnet).
- DHCP server active exclusively on the eth1 interface/subnet, issuing leases to armoire equipment.
- Split-DNS: `mon.essensys.fr` resolves to the gateway's eth1 IP for clients on the armoire segment; LAN DNS remains unaffected.
- Nginx bound to eth1 IP on port 80 (armoire path); Traefik bound to eth0 IP on port 443 (user HTTPS frontend). No cross-binding by default.
- NVMe partitioned, formatted ext4, mounted persistently; `data_dir` and log paths redirected there via bind mounts or variable override.
- Non-regression: existing `install.raspberrypi.yml` (single-NIC) untouched; gateway profile activates only when `gateway_dual_nic: true`.

**Non-Goals:**
- TLS on port 80 for the armoire segment (legacy HTTP is the documented path; a future variant may add it with DNS-01 but is out of scope here).
- Multi-gateway clustering or HA.
- Migration of existing eMMC data to NVMe (first-install assumption; documented workaround for existing installs).
- IPv6 support on eth1 (out of scope for the armoire bus).

## Decisions

### 1. Network stack: systemd-networkd

**Chosen**: `systemd-networkd` with `.network` unit templates.

**Rationale**: Pre-installed on Pi OS Bookworm, no extra packages, Ansible-friendly (`template` + `systemd` handler), supports `Match` by MAC for stable interface naming, integrates with `systemd-resolved` for upstream DNS.

**Alternatives considered**:
- `NetworkManager`: heavier, GUI-centric, requires `nmcli` wrappers in Ansible — less predictable in headless deploys.
- `netplan`: adds YAML-to-backend translation layer (can target networkd or NM). Acceptable but adds an indirection with no benefit on Bookworm where networkd is already native.
- `/etc/network/interfaces` (ifupdown): deprecated path on Bookworm; mixing it with networkd causes races.

### 2. DHCP server: dnsmasq

**Chosen**: `dnsmasq` scoped to `interface=eth1`.

**Rationale**: Single binary covers both DHCP and DNS split (address rewrite), minimal footprint, `interface=` directive prevents it from touching eth0, Ansible template straightforward, already evaluated for AdGuard integration.

**Alternatives considered**:
- `isc-dhcp-server`: DHCP only, separate DNS daemon needed for split. Two services vs. one.
- Extend AdGuard for DHCP: AdGuard's DHCP is a GUI/API feature not easily templated via Ansible; it would also conflict with dnsmasq port 53 on eth1.

**Conflict resolution**: dnsmasq listens on port 53 only on `eth1` (`listen-address=<eth1_ip>`). AdGuard continues to handle port 53 on `eth0` (or `127.0.0.1`). The two do not overlap.

### 3. Playbook structure: new playbook + boolean profile variable

**Chosen**: `install.gateway.yml` sets `gateway_dual_nic: true` and includes the three new roles before existing ones, then invokes existing roles whose templates have `{% if gateway_dual_nic %}` conditionals.

**Rationale**: Existing `install.raspberrypi.yml` stays completely untouched (zero regression risk). New gateway-specific behavior is opt-in. Variables are explicit and auditable.

**Alternative considered**: Inject gateway logic directly into existing roles via `when:` guards — harder to review, higher merge-conflict risk.

### 4. NVMe data placement: bind mounts via `essensys_nvme_mount`

**Chosen**: A single Ansible variable `essensys_nvme_mount` (default `/mnt/nvme`) defines the NVMe mount prefix. The `raspberry_gateway_nvme` role creates sub-directories and binds them:

| Bind source (NVMe) | Bind target (system path) |
|---|---|
| `{{ essensys_nvme_mount }}/data` | `{{ data_dir }}` (default `/opt/data`) |
| `{{ essensys_nvme_mount }}/logs` | `/var/log/essensys` |
| `{{ essensys_nvme_mount }}/prometheus` | `{{ data_dir }}/prometheus` |
| `{{ essensys_nvme_mount }}/redis` | `{{ data_dir }}/redis` |

**Rationale**: No OS duplication onto NVMe. Paths used by existing roles remain identical; only the underlying storage changes. Bind mounts are transparent to Docker containers.

**Alternative**: Set `data_dir` directly to an NVMe path — simpler but requires changing every existing role's default, increasing risk.

### 5. Service port binding (network_mode: host)

With `network_mode: host`, binding is controlled by the application's listen address:

- **Nginx**: `listen {{ gateway_eth1_ip }}:80;` in the armoire `server` block. The existing LAN/HTTPS block (`listen 443 ssl;`) continues to use `0.0.0.0` or is optionally restricted to `gateway_eth0_ip:443`.
- **Traefik**: `entryPoints.web.address: "{{ gateway_eth1_ip }}:80"` (armoire entry) + `entryPoints.websecure.address: "{{ gateway_eth0_ip }}:443"`. When `gateway_dual_nic: false`, `0.0.0.0` is used (current behavior).
- **AdGuard DNS**: unchanged on eth0; dnsmasq DNS on eth1 replaces per-segment resolution.

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| NVMe absent at boot causes bind-mount failure and blocked systemd units | `raspberry_gateway_nvme` role includes a `block/rescue` that fails with a clear error and a documented degraded-mode procedure (disable bind mounts via `gateway_nvme_bind_mounts: false`) |
| Interface naming (`eth0`/`eth1`) not stable across reboots | systemd-networkd `Match` by MAC address in `.network` unit; README documents how to identify MACs from `ip link` on first boot |
| dnsmasq port 53 clash with AdGuard on dual-stack if both bind `0.0.0.0:53` | dnsmasq `listen-address={{ gateway_eth1_ip }}` + `bind-interfaces`; AdGuard configured to bind `{{ gateway_eth0_ip }}` only when `gateway_dual_nic: true` |
| TLS cert for `mon.essensys.fr` invalid in private segment | Port 80 is the legacy path (no TLS required). If TLS is later needed, DNS-01 challenge via Traefik + Let's Encrypt is the only viable option; documented as an open item |
| Bind mounts not ordered before Docker systemd unit | `raspberry_gateway_nvme` installs a `local-fs-extra.mount` unit that Docker's systemd dependency graph picks up via `After=local-fs.target` |
| eMMC first-boot flash and EEPROM PCIe enablement not automatable | Documented step-by-step in each new role's `README.md` |

## Migration Plan

1. **Pre-flight** (manual, once per CM5): Flash eMMC with Pi OS Bookworm, enable PCIe/NVMe in EEPROM, verify `nvme0n1` visible, note MAC addresses of eth0/eth1.
2. **Inventory**: Set `gateway_dual_nic: true`, fill gateway variables (eth1 IP, DHCP range, NVMe mount, MAC addresses).
3. **Run** `ansible-playbook install.gateway.yml`.
4. **Validate** with checklist: `ip a`, `ss -tlnp`, `curl` from LAN and armoire segment, `findmnt`, `df -h`.
5. **Rollback**: Restore backed-up `/etc/systemd/network/*.network` files (role backs them up before replacing), `systemctl restart systemd-networkd`, remove dnsmasq package, restart Nginx/Traefik with prior config.

## Open Questions

- Should `docker-compose`'s `data_dir` be NVMe-only, or should container *images* also move to NVMe to protect eMMC from layer writes? (Current decision: images stay on eMMC; reconsider if eMMC fill rate proves problematic.)
- AdGuard web UI access from eth1: allow or block? (Current proposal: block — armoire clients should not reach the AdGuard admin panel.)
- Static lease reservations for armoire equipment: managed via Ansible variables or AdGuard GUI? (Current proposal: Ansible variables in dnsmasq config for full IaC traceability.)
