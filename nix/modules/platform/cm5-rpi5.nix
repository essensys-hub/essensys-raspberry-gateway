{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.essensys;
in
{
  options.services.essensys.platform.cm5 = {
    enable = lib.mkEnableOption "Raspberry Pi CM5 / Pi5-class platform profile (headless)";
  };

  config = lib.mkIf (cfg.enable && cfg.platform.cm5.enable) {
    # CM5 shares BCM2712 with Pi 5; community path uses linuxPackages_rpi4 on nixos-24.11/unstable.
    boot.kernelPackages = pkgs.linuxPackages_rpi4;

    boot.initrd.availableKernelModules = lib.mkMerge [
      (lib.mkIf cfg.nvme.enable [
        "nvme"
        "nvme-core"
      ])
    ];

    boot.initrd.kernelModules = lib.mkIf cfg.nvme.enable [
      "nvme"
      "nvme-core"
    ];

    # Headless gateway — no desktop
    services.xserver.enable = false;
    services.displayManager.sddm.enable = lib.mkForce false;

    # Generic extlinux path common for Raspberry Pi images in nixpkgs
    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible.enable = true;

    environment.systemPackages = with pkgs; [
      nvme-cli
      iproute2
      ethtool
    ];
  };
}
