## ADDED Requirements

### Requirement: CM5 hardware profile module
The system SHALL include a NixOS platform module for Raspberry Pi CM5 (BCM2712 class) covering boot loader configuration, kernel package selection, and headless (no desktop) profile.

#### Scenario: Headless system configuration
- **WHEN** `gateway-cm5` configuration is built
- **THEN** no desktop environment packages are included in the system closure by default

#### Scenario: Kernel module documented
- **WHEN** a maintainer reads `nix/modules/platform/cm5-rpi5.nix` (or equivalent)
- **THEN** the pinned kernel source (community flake or nixpkgs attribute) is explicit and documented

### Requirement: Firmware prerequisites documented
Documentation SHALL describe non-Nix CM5 steps required before first NixOS install: PCIe/NVMe enablement in firmware/EEPROM and verification that `nvme0n1` is visible.

#### Scenario: NVMe visibility prerequisite
- **WHEN** an operator follows `docs/nixos-install-cm5.md` pre-install section
- **THEN** they find steps to confirm `lsblk` shows `nvme0n1` before proceeding with install

### Requirement: Initrd includes NVMe support
The NixOS configuration SHALL include NVMe block and filesystem modules in the initrd so root or data mounts on NVMe are available at early boot when configured.

#### Scenario: NVMe modules in initrd
- **WHEN** inspecting the generated boot configuration
- **THEN** NVMe-related kernel modules are listed in initrd available modules
