## Why

The Essensys gateway CM5 needs a **declarative, reproducible deployment path** alongside the existing Ansible stack. NixOS on a dedicated `nixos` branch offers atomic upgrades, pinned dependencies, and module-based configuration for the full dual-NIC gateway (eth0 user HTTPS, eth1 armoire HTTP/DHCP/DNS) while preserving functional parity with `prompts/Gateway.md` and the Ansible change `essensys-gateway-dual-nic`. CM5 support is feasible via community flakes (not upstream-official), making this the right time to scaffold before hardware rollout.

## What Changes

- **New git branch** `nixos` in `essensys-raspberry-gateway` carrying a Nix flake (`flake.nix`, `nix/`) — `main` unchanged (hardware, openspec, Ansible prompts).
- **NixOS host** `gateway-cm5`: CM5 platform module (kernel, boot, DT/UEFI), dual-NIC networking, NVMe layout, and Essensys service stack.
- **Module `essensys.services.nginx`**: Nix-native Nginx config derived from repo `essensys-nginx` + gateway profile (listen eth1:80, reject eth0:80, BP_MQX_ETH proxy tuning).
- **Gateway modules**: `dual-nic.nix`, `dnsmasq-armoire.nix`, `nvme-layout.nix` — functional parity with Ansible gateway roles.
- **Service modules** (initial): backend Go, frontend static assets, Traefik TLS on eth0:443, Redis, Mosquitto; AdGuard optional/stub.
- **Integration** `essensys-nginx` as source of truth via `fetchFromGitHub` or local path in flake.
- **Documentation** `docs/nixos-install-cm5.md`: bootstrap, `nixos-install`, `nixos-rebuild switch --flake`, validation checklist.
- **CI target**: `nix flake check` / `nix build .#nixosConfigurations.gateway-cm5.config.system.build.toplevel` (native or cross aarch64).

## Capabilities

### New Capabilities

- `nix-flake-scaffold`: Flake entrypoint, directory layout, `gateway-cm5` host assembly, branch `nixos` workflow, build/check targets.
- `nix-platform-cm5`: CM5 / Pi5-class hardware profile — boot loader, kernel pin (community flake or `linuxPackages_rpi4`), firmware/DT prerequisites, headless profile.
- `nix-dual-nic-network`: systemd-networkd units for eth0 (LAN DHCP client) and eth1 (static RFC1918), MAC-stable matching, no default route on eth1.
- `nix-armoire-dhcp`: dnsmasq scoped to eth1 only — DHCP pool, reservations, no conflict with LAN DHCP on eth0.
- `nix-armoire-dns`: Split-DNS on eth1 — `mon.essensys.fr` resolves to gateway eth1 IP; upstream DNS for other queries.
- `nix-nvme-storage`: NVMe partition/mount on `nvme0n1`, eMMC vs NVMe data placement (`/opt/data`, logs, Redis, Prometheus paths).
- `nix-essensys-nginx`: NixOS module wrapping `essensys-nginx` configs with gateway listen addresses and BP_MQX_ETH API proxy requirements.
- `nix-service-stack`: Backend, frontend, Traefik, Redis, Mosquitto as NixOS modules or documented OCI/systemd stubs with NVMe-backed state paths.
- `nix-service-port-binding`: Interface-scoped listeners — Nginx :80 on eth1, Traefik :443 on eth0; no armoire HTTP on eth0.
- `nix-deployment-workflow`: First-install bootstrap, remote deploy, secrets handling (agenix/sops-nix), validation checklist, parity matrix vs Ansible.

### Modified Capabilities

*(none — NixOS path is opt-in on branch `nixos`; Ansible deployment on `main` / `essensys-ansible` is unchanged)*

## Impact

- **Repository**: `essensys-raspberry-gateway` branch `nixos` — new `flake.nix`, `nix/`, `docs/nixos-install-cm5.md`.
- **Related repos**: `essensys-nginx` (config source, rev pin in flake); read-only reference to `essensys-ansible`, `essensys-server-backend`, `essensys-server-frontend` for ports and behavior.
- **Dependencies**: Nix flakes, `nixos-raspberrypi` or equivalent community pin, nixpkgs channel/tag, optional `agenix`/`sops-nix` for secrets.
- **Hardware**: Raspberry Pi CM5 (eMMC + NVMe PCIe + dual Ethernet: native eth0, USB RTL8153 eth1).
- **Risk**: NixOS on CM5 is community-supported; kernel choice affects eth1 USB NIC and NVMe stability — documented in design, not a blocker for scaffold phase.
