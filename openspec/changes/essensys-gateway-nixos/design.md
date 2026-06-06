## Context

The Essensys gateway targets **Raspberry Pi CM5** with eMMC (`mmcblk0`), NVMe (`nvme0n1`), **eth0** (LAN / user HTTPS), and **eth1** (private armoire bus). Today, deployment is Ansible-based (`essensys-ansible/install.raspberrypi.yml`, future `install.gateway.yml` per change `essensys-gateway-dual-nic`). The prompt `prompts/NixOS.md` defines a **parallel NixOS profile** on branch `nixos` of `essensys-raspberry-gateway`.

NixOS on Pi 5 / CM5 is **not officially supported** in nixpkgs; community flakes (`nixos-raspberrypi`, rpi5-uefi) and vendor or `linuxPackages_rpi4` kernels are required. The product is **headless** (no GUI), which reduces complexity vs desktop Pi 5 setups.

Legacy armoire firmware **BP_MQX_ETH** requires plain HTTP on port 80, single-packet TCP responses for `/api/` — constraints already captured in `essensys-ansible/roles/raspberry_nginx/templates/default.conf.j2` and must be preserved in the NixOS Nginx module.

## Goals / Non-Goals

**Goals:**

- Declarative flake-based NixOS configuration `gateway-cm5` on branch `nixos`, buildable via `nix build`.
- Functional parity with Ansible gateway profile: dual-NIC, DHCP/DNS on eth1, NVMe data layout, Nginx armoire path, Traefik user HTTPS on eth0.
- Nix-native `essensys.services.nginx` module sourcing configs from `essensys-nginx` repo.
- Documented bootstrap and `nixos-rebuild switch --flake` deploy path.
- Ansible / `main` branch deployment **unchanged** — NixOS is opt-in.

**Non-Goals:**

- Replacing Ansible on `main` in this change.
- Official upstream nixpkgs CM5 support (wait for mainline Linux/U-Boot).
- TLS on port 80 for armoire segment (legacy HTTP documented path).
- Full production hardening of every service (AdGuard, OpenClaw, Prometheus) in v1 — stubs acceptable with TODOs.
- Multi-node HA or remote fleet orchestration beyond single-host `nixos-rebuild`.

## Decisions

### 1. Branch and repository layout

**Chosen**: All Nix artifacts live on git branch **`nixos`** in `essensys-raspberry-gateway`; `main` keeps hardware KiCad, openspec, Ansible prompts only.

**Rationale**: Clear separation of deployment paradigms; avoids breaking hardware contributors with flake complexity.

**Structure** (from `prompts/NixOS.md` §2): `flake.nix`, `nix/hosts/gateway-cm5/`, `nix/modules/{essensys,gateway,platform}/`, `docs/nixos-install-cm5.md`.

### 2. Platform: community flake + headless CM5 profile

**Chosen**: Pin **`nixos-raspberrypi`** (or equivalent maintained flake) for installer images and kernel; module `nix/platform/cm5-rpi5.nix` wraps boot, DT, and kernel package selection.

**Alternatives**:
- Pure nixpkgs `linuxPackages_rpi4` on unstable — lighter pin but less CM5-specific testing.
- Raspberry Pi OS + Nix as secondary package manager — rejected; defeats reproducibility goal.

**CM5 specifics**: Document one-time EEPROM/PCIe NVMe enablement outside Nix; flake assumes `nvme0n1` visible after firmware step.

### 3. Networking: systemd-networkd + dnsmasq (parity with Ansible design)

**Chosen**: `networking.useNetworkd = true`; generated `.network` units with `Match` on MAC addresses (`gateway.eth0Mac`, `gateway.eth1Mac` options). **dnsmasq** on eth1 only via `services.dnsmasq` or custom module — same split as `essensys-gateway-dual-nic` design.

**DNS conflict mitigation**: dnsmasq binds `listen-address = eth1_ip`; AdGuard (if enabled) binds eth0 only — mirror Ansible AdGuard change.

### 4. Nginx: native `services.nginx` (Option A)

**Chosen**: NixOS **`services.nginx`** with config built from `essensys-nginx` files + gateway template logic (eth1 listen, eth0:80 reject, BP_MQX_ETH buffers).

**Alternatives**:
- Docker `essensyshub/essensys-nginx` with `networkMode = host` — faster parity, extra layer, harder bind-IP tuning in Nix.
- Standalone package only — no systemd integration.

**Source pin**: `fetchFromGitHub` on `essensys-nginx` at tagged rev; local path override for dev via flake input or `NIX_PATH`.

### 5. Application stack: phased native vs OCI

**Chosen (v1 scaffold)**:
- **Nginx**: native (decision 4).
- **Traefik**: native NixOS service or `services.traefik` with static config — bind `websecure` to `eth0_ip:443`.
- **Backend Go**: systemd service running packaged binary or container with `networkMode host` — **implementer picks** in tasks; design prefers **OCI with host network** for v1 speed if Nix packaging backend is heavy.
- **Frontend**: static files in Nix store path, copied/symlinked to `services.essensys.nginx.frontendRoot`.
- **Redis / Mosquitto**: `services.redis` / `services.mosquitto` with `datadir` on NVMe.

Document choice per service in module README comments.

### 6. NVMe layout: declarative `fileSystems` + subpaths

**Chosen**: Mount NVMe at `/mnt/nvme` (configurable); subdirs `data`, `logs`, `prometheus`, `redis` owned by `essensys` user; `services.essensys.dataDir = "/mnt/nvme/data"` (or bind `/opt/data` → NVMe via `fileSystems` bind option in Nix).

**Rationale**: Matches Ansible bind-mount strategy without duplicating OS onto NVMe.

**eMMC**: `/`, `/nix/store`, lightweight configs only.

### 7. Secrets: agenix or sops-nix (placeholder in v1)

**Chosen**: Module options for ACME email and domain; actual secrets via **agenix** encrypted files in repo (documented pattern), not committed plaintext.

**v1 scaffold**: may use self-signed or staging certs with explicit TODO.

### 8. Deployment workflow

**Chosen**:
1. Manual CM5 firmware/NVMe prep (documented).
2. Build/installer image from flake or flash minimal aarch64 + `nixos-install --flake .#gateway-cm5`.
3. Ongoing: `nixos-rebuild switch --flake .#gateway-cm5 --target-host root@<eth0-ip>`.

**Future**: Colmena / deploy-rs for fleet — out of scope v1.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| CM5/NixOS community-only support | Pin flake.lock; document kernel choice; hardware validation checklist before production |
| USB eth1 (RTL8153) driver issues on wrong kernel | Test with vendor kernel; document working pin in `hardware.nix` |
| NVMe missing at boot | `boot.initrd.availableKernelModules`; fail-closed option or documented degraded mode without bind mounts |
| dnsmasq vs AdGuard port 53 clash | Strict bind-address per interface (same as Ansible design) |
| BP_MQX_ETH regression if Nginx config simplified | Spec `nix-essensys-nginx` mandates proxy_buffering/gzip-off; integration test from armoire segment |
| Dual maintenance Ansible + NixOS | Parity matrix in docs; shared behavioral specs (hostname, ports, paths) |
| Large flake build time on CM5 | Binary cache (community or self-hosted); cross-build from x86 CI |

## Migration Plan

1. **Phase 0** (this change): Scaffold flake on branch `nixos`; modules compile; docs written; no production cutover.
2. **Phase 1**: Boot CM5 from installer; validate network + NVMe + Nginx on hardware.
3. **Phase 2**: Enable backend/Traefik/Redis/Mosquitto; run side-by-side validation vs Ansible gateway on second unit.
4. **Phase 3** (future): Optional production default switch per site; Ansible remains fallback.

**Rollback**: Prior generation via Nix boot profile or re-flash eMMC; keep Ansible path documented.

## Open Questions

- Final kernel pin: `nixos-raspberrypi` vendor kernel vs `linuxPackages_rpi4` on 24.11/unstable?
- Backend v1: Nix-packaged Go vs OCI `essensyshub/essensys-backend`?
- AdGuard on NixOS: use existing nixpkgs module or defer / replace with unbound?
- CI: GitHub Actions with `nix build` + `ubuntu-latest` + QEMU binfmt for aarch64?
- Should `essensys-nginx` gain a `nix/` subdirectory long-term or stay fetch-only from gateway flake?
