{
  config,
  lib,
  ...
}:
{
  # Boot/firmware paths are finalized after first nixos-install on CM5 hardware.
  # Kernel and initrd NVMe modules are set by nix/modules/platform/cm5-rpi5.nix.
}
