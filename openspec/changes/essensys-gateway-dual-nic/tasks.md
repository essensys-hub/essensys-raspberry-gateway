## 1. Repository and Playbook Scaffold

- [x] 1.1 Create `install.gateway.yml` playbook that sets `gateway_dual_nic: true` and chains all roles in correct order (new gateway roles first, then existing roles)
- [x] 1.2 Create role skeleton `roles/raspberry_gateway_network/` with `defaults/main.yml`, `tasks/main.yml`, `templates/`, `handlers/main.yml`, `README.md`
- [x] 1.3 Create role skeleton `roles/raspberry_gateway_dhcp/` with `defaults/main.yml`, `tasks/main.yml`, `templates/`, `handlers/main.yml`, `README.md`
- [x] 1.4 Create role skeleton `roles/raspberry_gateway_nvme/` with `defaults/main.yml`, `tasks/main.yml`, `handlers/main.yml`, `README.md`
- [x] 1.5 Define all gateway variables with defaults in each role's `defaults/main.yml`: `gateway_dual_nic`, `gateway_eth0_mac`, `gateway_eth1_mac`, `gateway_eth1_ip`, `gateway_eth1_prefix`, `gateway_eth0_ip`, `gateway_armoire_hostname`, `gateway_dhcp_range_start`, `gateway_dhcp_range_end`, `gateway_dhcp_lease_time`, `gateway_dhcp_reservations`, `gateway_upstream_dns`, `gateway_nvme_device`, `essensys_nvme_mount`, `gateway_nvme_bind_mounts_enabled`, `gateway_nvme_bind_mounts`

## 2. Role: raspberry_gateway_network

- [x] 2.1 Write Ansible template `templates/10-eth0.network.j2` for systemd-networkd eth0 DHCP client unit (Match by MAC `gateway_eth0_mac`)
- [x] 2.2 Write Ansible template `templates/20-eth1.network.j2` for systemd-networkd eth1 static IP unit (Match by MAC `gateway_eth1_mac`, IP from `gateway_eth1_ip/gateway_eth1_prefix`, no default route)
- [x] 2.3 Write `tasks/main.yml`: backup existing `.network` files with timestamp, deploy templates, trigger handler
- [x] 2.4 Write `handlers/main.yml`: restart `systemd-networkd` on change
- [x] 2.5 Write role `README.md` documenting non-automatable steps (MAC address discovery via `ip link`, CM5 first-boot eMMC flash)
- [x] 2.6 Verify role is skipped (`when: gateway_dual_nic`) so standard `install.raspberrypi.yml` is unaffected

## 3. Role: raspberry_gateway_dhcp (dnsmasq)

- [x] 3.1 Add task to install `dnsmasq` package via `apt`
- [x] 3.2 Write template `templates/dnsmasq.conf.j2` with `interface=eth1`, `bind-interfaces`, `listen-address={{ gateway_eth1_ip }}`, DHCP range, lease time, option 6 (DNS), `address=/{{ gateway_armoire_hostname }}/{{ gateway_eth1_ip }}`, upstream DNS forwarding
- [x] 3.3 Add task to template static DHCP reservations from `gateway_dhcp_reservations` list (loop generating `dhcp-host=` lines in dnsmasq config or a separate include file)
- [x] 3.4 Write `tasks/main.yml`: deploy config, enable and start `dnsmasq` service, trigger handler on change
- [x] 3.5 Write `handlers/main.yml`: reload dnsmasq on config change
- [x] 3.6 Add task to verify no port 53 conflict: fail if something else is already listening on `gateway_eth1_ip:53` before dnsmasq starts
- [x] 3.7 Write role `README.md` documenting DHCP pool variables and static reservation format

## 4. Role: raspberry_gateway_nvme

- [x] 4.1 Add task to detect NVMe device: `stat {{ gateway_nvme_device }}` and fail with clear message if absent
- [x] 4.2 Add task to create partition on NVMe (using `community.general.parted` or `ansible.builtin.command` with `parted`), idempotent (check for existing partition first)
- [x] 4.3 Add task to format partition as ext4 with label `essensys-data` (idempotent: skip if label already set)
- [x] 4.4 Add task to retrieve partition UUID (`blkid`) and register as variable for fstab
- [x] 4.5 Add task to create mount point directory at `essensys_nvme_mount`
- [x] 4.6 Add task to add fstab entry using UUID with `noatime` options (using `ansible.posix.mount` module)
- [x] 4.7 Add task to mount the NVMe partition immediately if not already mounted
- [x] 4.8 Add tasks to create NVMe subdirectories (`data`, `logs`, `prometheus`, `redis`, etc.) and set ownership to `essensys` user
- [x] 4.9 Add tasks to bind-mount NVMe subdirectories to target paths (loop over `gateway_nvme_bind_mounts`), guarded by `gateway_nvme_bind_mounts_enabled`, with fstab entries for persistence
- [x] 4.10 Add task to check and configure Docker systemd drop-in override with `After=mnt-nvme.mount` (or equivalent) so Docker starts after NVMe is mounted
- [x] 4.11 Write role `README.md` with: pre-requisites (PCIe/NVMe enablement in CM5 EEPROM), post-install validation commands (`lsblk`, `findmnt`, `df -h`), degraded-mode procedure, rollback steps

## 5. Nginx Template Modifications

- [x] 5.1 Read current `roles/raspberry_nginx/templates/default.conf.j2` and identify the port 80 server block
- [x] 5.2 Add `{% if gateway_dual_nic %}` conditional: `listen {{ gateway_eth1_ip }}:80;` in the armoire server block; `listen 80;` (default) in the else branch
- [x] 5.3 Add conditional for the HTTPS/443 server block: `listen {{ gateway_eth0_ip }}:443 ssl;` when `gateway_dual_nic`, else `listen 443 ssl;` (note: no existing 443 block in Nginx — handled by Traefik, not applicable here)
- [x] 5.4 Add a catch-all server block that returns 444 on eth0:80 when `gateway_dual_nic` is true (prevent armoire vhost exposure on LAN)
- [x] 5.5 Validate template renders correctly for both `gateway_dual_nic: true` and `gateway_dual_nic: false` scenarios

## 6. Traefik Template Modifications

- [x] 6.1 Read current `roles/raspberry_traefik/templates/traefik.yml.j2` and identify `entryPoints` section
- [x] 6.2 Add conditional: when `gateway_dual_nic`, set `websecure.address: "{{ gateway_eth0_ip }}:443"`; else use `":443"` (port 80 is Nginx-only — no web entrypoint added to avoid conflict)
- [x] 6.3 Validate Traefik config renders correctly for both profile modes

## 7. AdGuard Template Modifications

- [x] 7.1 Read current `roles/raspberry_adguard/` role and identify bind address configuration
- [x] 7.2 When `gateway_dual_nic`, configure AdGuard DNS to bind to `gateway_eth0_ip` only (not `0.0.0.0`) to avoid conflict with dnsmasq on eth1
- [x] 7.3 Add firewall rule (iptables/nftables task) to block access to AdGuard admin UI port from the `gateway_eth1_ip` subnet

## 8. Integration and Validation

- [x] 8.1 Create a sample inventory file `inventory.gateway` with all required gateway variables documented and example values
- [ ] 8.2 Run `ansible-playbook install.gateway.yml --check` in dry-run mode against the inventory (requires real/test host)
- [ ] 8.3 Run `ansible-playbook install.raspberrypi.yml --check` and verify no gateway tasks execute (non-regression) (requires real/test host)
- [ ] 8.4 On real hardware: run `install.gateway.yml` and validate `ip a` shows eth0 with LAN IP and eth1 with static IP
- [ ] 8.5 On real hardware: run `ss -tlnp` and verify Nginx on `gateway_eth1_ip:80`, Traefik on `gateway_eth0_ip:443`, dnsmasq on `gateway_eth1_ip:53`
- [ ] 8.6 From LAN (eth0): `curl -k https://{{ gateway_eth0_ip }}` returns frontend (HTTP 200 or redirect)
- [ ] 8.7 From armoire segment (eth1): `curl http://{{ gateway_eth1_ip }}` returns expected API response (legacy BP_MQX_ETH path)
- [ ] 8.8 From armoire segment: `dig mon.essensys.fr @{{ gateway_eth1_ip }}` resolves to `gateway_eth1_ip`
- [ ] 8.9 Verify NVMe: `findmnt {{ essensys_nvme_mount }}` and `df -h {{ data_dir }}` show NVMe device
- [ ] 8.10 Run playbook a second time and confirm all tasks report `ok` (idempotence check)
- [ ] 8.11 Reboot the gateway and re-run all validation checks to confirm persistence
