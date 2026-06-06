## ADDED Requirements

### Requirement: Installation documentation
The repository SHALL include `docs/nixos-install-cm5.md` covering firmware prep, image install, first `nixos-install --flake`, and post-install validation.

#### Scenario: Doc covers bootstrap commands
- **WHEN** an operator reads the install doc
- **THEN** they find explicit commands for `nixos-install` or installer image workflow and `nixos-rebuild switch --flake`

### Requirement: Remote deployment via nixos-rebuild
The documented workflow SHALL support deploying configuration changes from a development machine using `nixos-rebuild switch --flake .#gateway-cm5 --target-host`.

#### Scenario: Remote rebuild documented
- **WHEN** the install doc describes ongoing updates
- **THEN** it includes the `nixos-rebuild switch --flake` target-host pattern

### Requirement: Secrets not committed in plaintext
Documentation SHALL describe use of agenix, sops-nix, or equivalent for ACME credentials and tokens. No production secrets SHALL be committed to the repository.

#### Scenario: Secrets section present
- **WHEN** reading deployment documentation
- **THEN** a secrets management section exists with at least one supported approach

### Requirement: Hardware validation checklist
Documentation SHALL include a checklist mirroring `prompts/NixOS.md`: `ip a`, `networkctl`, `ss -tlnp`, curl from LAN and armoire segment, `findmnt`, `df -h`.

#### Scenario: Validation checklist complete
- **WHEN** an operator completes the post-install checklist on hardware
- **THEN** they can verify dual-NIC, DNS, port binding, and NVMe layout without referring to external docs

### Requirement: Parity matrix vs Ansible
Documentation SHALL include a table mapping Ansible gateway capabilities (`essensys-gateway-dual-nic`) to NixOS modules/options.

#### Scenario: Parity matrix exists
- **WHEN** reading `docs/nixos-install-cm5.md` or linked doc
- **THEN** a parity matrix lists network, DHCP, DNS, nginx, traefik, and NVMe equivalents
