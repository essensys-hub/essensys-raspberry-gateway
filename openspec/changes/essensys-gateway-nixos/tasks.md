## 1. Branch and Flake Scaffold

- [x] 1.1 Ensure git branch `nixos` exists in `essensys-raspberry-gateway` and is the working branch for Nix work
- [x] 1.2 Create `flake.nix` with inputs (nixpkgs, nixos-raspberrypi or chosen platform flake, essensys-nginx source)
- [x] 1.3 Create `nix/hosts/gateway-cm5/default.nix` assembling all gateway modules
- [x] 1.4 Create `nix/hosts/gateway-cm5/hardware.nix` stub for CM5 platform options
- [x] 1.5 Run `nix flake check` and fix evaluation errors until clean

## 2. Platform Module (CM5)

- [x] 2.1 Create `nix/modules/platform/cm5-rpi5.nix` with boot loader, kernel pin, headless profile
- [x] 2.2 Add initrd modules for NVMe block/filesystem support
- [x] 2.3 Document firmware/EEPROM NVMe enablement steps in module README or `docs/nixos-install-cm5.md`

## 3. Gateway Network Modules

- [x] 3.1 Create `nix/modules/gateway/dual-nic.nix` with options: `eth0Mac`, `eth1Mac`, `eth1Address`, `eth1Prefix`
- [x] 3.2 Generate systemd-networkd `.network` units for eth0 (DHCP) and eth1 (static, no default route)
- [x] 3.3 Create `nix/modules/gateway/dnsmasq-armoire.nix` with DHCP pool, lease time, reservations, eth1-only bind
- [x] 3.4 Add dnsmasq DNS rewrite for `mon.essensys.fr` → eth1 IP (configurable hostname option)
- [x] 3.5 Verify no port 53/67 conflict with optional AdGuard on eth0 (bind-address separation)

## 4. NVMe Storage Module

- [x] 4.1 Create `nix/modules/gateway/nvme-layout.nix` with `fileSystems` for NVMe mount (default `/mnt/nvme`)
- [x] 4.2 Define subpaths: `data`, `logs`, `prometheus`, `redis` with `essensys` user ownership via `systemd.tmpfiles`
- [x] 4.3 Wire `services.essensys.dataDir` to NVMe-backed path; ensure journal/log paths documented or redirected
- [x] 4.4 Add clear failure message or degraded-mode option when NVMe device absent

## 5. Essensys Nginx Module

- [x] 5.1 Create `nix/modules/essensys/nginx.nix` with `services.essensys.nginx` options
- [x] 5.2 Add flake input or `fetchFromGitHub` for `essensys-nginx` at pinned rev
- [x] 5.3 Generate server config: listen `eth1_ip:80`, reject `eth0_ip:80`, SPA `/`, proxy `/api/` → `:7070`
- [x] 5.4 Apply BP_MQX_ETH proxy settings: `proxy_buffering on`, `gzip off`, buffer sizes from Ansible template
- [x] 5.5 Add proxy routes for `/mcp/` and `/admin/` with configurable backend ports
- [x] 5.6 Run `nginx -t` in build or activation check

## 6. Service Stack Modules

- [x] 6.1 Create `nix/modules/essensys/backend.nix` — systemd or OCI host-network service on port 7070
- [x] 6.2 Create `nix/modules/essensys/frontend.nix` — fetch/build static assets to `frontendRoot`
- [x] 6.3 Create `nix/modules/essensys/traefik.nix` — TLS entrypoint bound to `eth0_ip:443`
- [x] 6.4 Create `nix/modules/essensys/redis.nix` and `mosquitto.nix` with NVMe datadir paths
- [x] 6.5 Add disabled stubs for AdGuard, Prometheus, MCP with TODO comments and enable options

## 7. Port Binding Integration

- [x] 7.1 Wire gateway profile flag so Nginx and Traefik bind addresses come from live eth0/eth1 IPs or static config
- [x] 7.2 Verify generated config: Nginx :80 on eth1 only; Traefik :443 on eth0 only
- [x] 7.3 Add activation script or documentation note if IP assignment order requires network-online.target

## 8. Deployment Documentation and Secrets

- [x] 8.1 Write `docs/nixos-install-cm5.md`: firmware prep, install, first boot, remote rebuild
- [x] 8.2 Add hardware validation checklist (`ip a`, `ss -tlnp`, curl LAN/armoire, `findmnt`, `df -h`)
- [x] 8.3 Add Ansible ↔ NixOS parity matrix referencing `essensys-gateway-dual-nic`
- [x] 8.4 Document agenix or sops-nix pattern for ACME email and secrets (no plaintext in git)
- [x] 8.5 Document `nixos-rebuild switch --flake .#gateway-cm5 --target-host root@<eth0-ip>`

## 9. Build and Hardware Validation

- [x] 9.1 Run `nix build .#nixosConfigurations.gateway-cm5.config.system.build.toplevel` (native or cross aarch64)
- [ ] 9.2 Boot CM5 from installer or installed flake configuration
- [ ] 9.3 Validate eth0 DHCP and eth1 static IP after reboot
- [ ] 9.4 Validate dnsmasq lease and `mon.essensys.fr` resolution on eth1
- [ ] 9.5 Validate `curl -k https://<eth0_ip>/` (frontend) and armoire `curl http://<eth1_ip>/api/...`
- [ ] 9.6 Validate NVMe mounts and data paths not on eMMC
- [ ] 9.7 Run second `nixos-rebuild switch` and confirm idempotent activation

## 10. CI (Optional v1)

- [x] 10.1 Add GitHub Actions workflow running `nix flake check` on push to branch `nixos`
- [x] 10.2 Optionally add cross-build job for aarch64 with binfmt/QEMU
