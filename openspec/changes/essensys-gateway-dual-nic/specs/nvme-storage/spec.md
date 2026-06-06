## ADDED Requirements

### Requirement: NVMe device detected and validated before use
The `raspberry_gateway_nvme` role SHALL verify that the NVMe device (`/dev/nvme0n1` by default, configurable via `gateway_nvme_device`) is present before performing any partitioning or formatting. If the device is absent, the role SHALL fail with a clear error message rather than silently skipping.

#### Scenario: Role fails clearly when NVMe is absent
- **WHEN** `gateway_nvme_device` does not exist (e.g., no NVMe installed)
- **THEN** Ansible fails with a human-readable message: "NVMe device {{ gateway_nvme_device }} not found. Check hardware and PCIe configuration."

#### Scenario: Role proceeds when NVMe is present
- **WHEN** `gateway_nvme_device` exists and is accessible
- **THEN** the role continues to partition, format, and mount steps without error

### Requirement: NVMe partitioned and formatted with ext4
The role SHALL create a single partition on the NVMe device (using the full disk or a configured size), format it as ext4, and label it `essensys-data`. The operation SHALL be idempotent: if the partition and filesystem already exist with the correct label, no re-partitioning or re-formatting SHALL occur.

#### Scenario: First-run partitioning and formatting
- **WHEN** the NVMe device has no partition table
- **THEN** the role creates one partition, formats it ext4, and assigns the label `essensys-data`

#### Scenario: Idempotent on re-run
- **WHEN** the NVMe device is already partitioned and formatted with label `essensys-data`
- **THEN** the role makes no changes to the partition table or filesystem

### Requirement: NVMe partition mounted persistently at configured path
The NVMe partition SHALL be mounted at `essensys_nvme_mount` (default `/mnt/nvme`) and an entry SHALL be added to `/etc/fstab` using the partition's UUID (not device path) with options `defaults,noatime`. The mount SHALL be active after every boot.

#### Scenario: NVMe mounted after first apply
- **WHEN** the role has been applied
- **THEN** `findmnt {{ essensys_nvme_mount }}` shows the NVMe partition mounted at the configured path

#### Scenario: NVMe mounted after reboot
- **WHEN** the system reboots
- **THEN** the NVMe partition is automatically mounted at `essensys_nvme_mount` before `local-fs.target` completes

#### Scenario: fstab uses UUID not device path
- **WHEN** the fstab entry is inspected
- **THEN** the mount is identified by `UUID=<uuid>`, not by `/dev/nvme0n1p1`

### Requirement: Write-heavy paths redirected to NVMe via bind mounts
The role SHALL create subdirectories on the NVMe volume and bind-mount them to the target paths listed in `gateway_nvme_bind_mounts` (a list of `{src, dest}` dicts). Default bind mounts SHALL include at minimum: `data_dir` (`/opt/data`), `/var/log/essensys`, Prometheus TSDB, and Redis data directory.

#### Scenario: data_dir resides on NVMe
- **WHEN** the role has been applied and the system has booted
- **THEN** `findmnt {{ data_dir }}` shows the source device as the NVMe partition

#### Scenario: Log writes go to NVMe
- **WHEN** an application writes to `/var/log/essensys/app.log`
- **THEN** `df /var/log/essensys` reports the NVMe device, not the eMMC

### Requirement: Systemd units depend on NVMe mount
Docker and any other systemd units that use NVMe-backed paths SHALL be configured with `After=local-fs.target` (or a dedicated `mnt-nvme.mount` dependency) so they start only after the NVMe is mounted.

#### Scenario: Docker starts after NVMe is mounted
- **WHEN** the system boots
- **THEN** the Docker service starts after the NVMe bind mounts are active (`systemctl show docker --property=After` includes the NVMe mount unit)

### Requirement: eMMC data paths not duplicated on NVMe
The OS, packages, and static application source files SHALL remain on eMMC (`mmcblk0`). The role SHALL NOT copy the OS partition to NVMe or alter the boot device configuration.

#### Scenario: OS partition remains on eMMC
- **WHEN** `lsblk` is run after installation
- **THEN** the root filesystem `/` is on `mmcblk0` and the NVMe hosts only the data mount

### Requirement: Role provides degraded mode when NVMe bind mounts are disabled
The variable `gateway_nvme_bind_mounts_enabled` (default `true`) SHALL allow disabling bind mounts (e.g., during initial troubleshooting). When `false`, the NVMe is still mounted but no bind mounts are created and a warning is logged.

#### Scenario: Bind mounts skipped in degraded mode
- **WHEN** `gateway_nvme_bind_mounts_enabled: false` and the role is applied
- **THEN** the NVMe is mounted at `essensys_nvme_mount` but `data_dir` still points to eMMC and Ansible logs a warning

### Requirement: Post-install validation commands documented
The role README SHALL include a validation checklist with commands: `lsblk`, `findmnt`, `df -h`, and a write-test command to confirm write I/O targets NVMe.

#### Scenario: Operator can verify NVMe usage
- **WHEN** an operator runs `lsblk` and `df -h` after deployment
- **THEN** the output clearly shows the NVMe device hosting `essensys_nvme_mount` and all bound subdirectories
