## ADDED Requirements

### Requirement: NVMe mounted persistently
The system SHALL mount the NVMe device (`nvme0n1` partition) at a configurable mount point (default `/mnt/nvme`) via declarative `fileSystems` in NixOS configuration.

#### Scenario: NVMe mount after reboot
- **WHEN** the gateway reboots after successful install
- **THEN** `findmnt` shows the NVMe filesystem mounted at the configured mount point

#### Scenario: Missing NVMe fails clearly
- **WHEN** NVMe is required but `nvme0n1` is absent at boot
- **THEN** activation fails or documented degraded mode is entered with an explicit error message (no silent eMMC fallback for data paths)

### Requirement: Write-heavy paths on NVMe
Logs, application data directory, Redis data, and Prometheus TSDB (when enabled) SHALL reside on NVMe-backed paths, not on eMMC root.

#### Scenario: Data directory on NVMe
- **WHEN** `df -h` is run on the configured `services.essensys.dataDir` path
- **THEN** the underlying device is the NVMe partition, not `mmcblk0`

#### Scenario: System logs on NVMe
- **WHEN** journal or application logs are written under the configured log path
- **THEN** the path resolves to a subdirectory of the NVMe mount

### Requirement: eMMC reserved for OS and Nix store
The root filesystem and `/nix/store` SHALL remain on eMMC (`mmcblk0`) unless explicitly migrated in a future change.

#### Scenario: Nix store on eMMC
- **WHEN** `df -h /nix/store` is run
- **THEN** the device is `mmcblk0` (or root partition on eMMC)
