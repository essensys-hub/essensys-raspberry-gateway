## Why

The Essensys gateway must physically isolate user-facing traffic (LAN/HTTPS on eth0) from equipment bus traffic (armoire/HTTP on eth1) while retaining full backward compatibility with the legacy BP_MQX_ETH firmware client. A Raspberry Pi CM5 is now the target hardware, adding NVMe storage that must absorb write-heavy workloads (logs, TSDB, caches) to prevent premature eMMC wear-out.

## What Changes

- **New Ansible role** `raspberry_gateway_network`: systemd-networkd configuration for eth0 (LAN, DHCP client) and eth1 (static IP, private armoire segment).
- **New Ansible role** `raspberry_gateway_dhcp`: ISC DHCP / `dnsmasq` server scoped strictly to eth1 — no conflict with upstream LAN DHCP.
- **New Ansible role** `raspberry_gateway_nvme`: NVMe device detection, partitioning, ext4 filesystem, persistent mount, and bind-mount rules routing write-heavy paths to NVMe.
- **New playbook** `install.gateway.yml` invoking existing roles with a gateway profile variable `gateway_dual_nic: true` plus the three new roles above.
- **Modified templates** for Nginx, Traefik, and AdGuard: conditional `listen`/`bind`/`entryPoints` directives that scope port 80 to eth1 and port 443 to eth0 when `gateway_dual_nic` is true.
- **Split-DNS rule** in AdGuard (or dnsmasq): `mon.essensys.fr` rewrites to the eth1 gateway IP for armoire segment clients.
- **README** in each new role documenting non-automatable steps (first-boot eMMC flash, EEPROM/PCIe NVMe enablement on CM5).

## Capabilities

### New Capabilities

- `dual-nic-network`: Stable, idempotent systemd-networkd configuration for eth0 (LAN DHCP client) and eth1 (static IPv4, private armoire subnet). Covers interface naming by MAC, network unit templates, and handler-triggered restarts.
- `armoire-dhcp`: DHCP service running exclusively on the eth1 interface/subnet — assigns leases to armoire equipment, does not interfere with LAN DHCP, supports idempotent pool and reservation configuration via Ansible variables.
- `armoire-dns`: Split-DNS ensuring `mon.essensys.fr` resolves to the gateway's eth1 IP for clients on the armoire segment, while upstream/AdGuard resolution continues normally for LAN clients on eth0.
- `service-port-binding`: Interface-scoped listener configuration for Nginx (`:80` bound to eth1 IP for legacy BP_MQX_ETH), Traefik (`:443` bound to eth0 IP for user HTTPS frontend), and AdGuard — all compatible with `network_mode: host`.
- `nvme-storage`: CM5 NVMe device preparation (partition, ext4, fstab, `noatime`), bind-mount strategy routing `data_dir` / logs / TSDB / caches to NVMe, and `systemd` dependency ordering so containers start after NVMe is mounted.

### Modified Capabilities

*(none — existing single-NIC deployment path is unchanged when `gateway_dual_nic: false`)*

## Impact

- **Ansible roles affected**: `raspberry_nginx`, `raspberry_traefik`, `raspberry_adguard`, `raspberry_compose` — template conditionals added, no structural changes to defaults.
- **New roles**: `raspberry_gateway_network`, `raspberry_gateway_dhcp`, `raspberry_gateway_nvme`.
- **New playbook**: `install.gateway.yml` — existing `install.raspberrypi.yml` untouched.
- **Variables**: new top-level gateway profile variables (`gateway_dual_nic`, `gateway_eth1_ip`, `gateway_eth1_subnet`, `gateway_dhcp_range_start/end`, `essensys_nvme_mount`, etc.).
- **OS dependencies**: `systemd-networkd` (already present on Pi OS Bookworm), `dnsmasq` or `isc-dhcp-server` for DHCP, `util-linux`/`e2fsprogs` for NVMe setup.
- **TLS risk**: `mon.essensys.fr` will have a private-only A record on the armoire segment — any TLS cert for that hostname must be provisioned via DNS-01 challenge or a self-signed CA; port 80 (HTTP) is the documented legacy path, so no TLS is required on the armoire side by default.
