# CM5 / Pi5 NixOS platform notes

This module enables a **headless** Raspberry Pi CM5 profile using `pkgs.linuxPackages_rpi4`
(nixpkgs community path for Pi 5-class hardware).

## Prerequisites (manual, before first NixOS install)

1. Flash or install base firmware on CM5 eMMC.
2. Enable **PCIe / NVMe** in CM5 EEPROM or firmware config per Raspberry Pi documentation.
3. Verify `lsblk` shows `nvme0n1` before relying on `services.essensys.nvme`.
4. Note **MAC addresses** for eth0 (native) and eth1 (USB RTL8153 on Essensys IO board):
   `ip link show`

## Kernel alternatives

- **Default here**: `linuxPackages_rpi4` on nixos-24.11
- **Alternative**: pin `nixos-raspberrypi` flake input for vendor kernel (see `docs/nixos-install-cm5.md`)

## Initrd

NVMe modules are added when `services.essensys.nvme.enable = true`.
