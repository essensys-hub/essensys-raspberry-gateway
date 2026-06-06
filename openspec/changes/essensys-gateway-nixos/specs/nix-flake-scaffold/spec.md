## ADDED Requirements

### Requirement: Nix flake entrypoint on branch nixos
The repository SHALL provide a `flake.nix` on git branch `nixos` that defines `nixosConfigurations.gateway-cm5` and exposes build/check targets consumable by `nix build` and `nix flake check`.

#### Scenario: Flake evaluates successfully
- **WHEN** a developer runs `nix flake check` in the repository root on branch `nixos`
- **THEN** the flake evaluates without error

#### Scenario: System toplevel builds
- **WHEN** a developer runs `nix build .#nixosConfigurations.gateway-cm5.config.system.build.toplevel`
- **THEN** the build completes successfully (natively on aarch64 or via cross-compilation)

### Requirement: Standard directory layout
The branch SHALL follow the layout documented in `prompts/NixOS.md`: `nix/hosts/gateway-cm5/`, `nix/modules/essensys/`, `nix/modules/gateway/`, `nix/modules/platform/`, and `docs/nixos-install-cm5.md`.

#### Scenario: Host module assembles gateway modules
- **WHEN** inspecting `nix/hosts/gateway-cm5/default.nix`
- **THEN** it imports platform, gateway, and essensys modules required for the gateway profile

### Requirement: Main branch unaffected
The `main` branch SHALL NOT require Nix or flake inputs for its primary workflow (hardware, openspec, Ansible prompts).

#### Scenario: No flake on main required for hardware work
- **WHEN** a contributor works on KiCad or openspec on `main` without Nix installed
- **THEN** they can complete their workflow without flake dependencies
