{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/minimal.nix")
    ./hardware-cm5.generated.nix
  ];

  boot.loader.grub.enable = false;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Valeurs relevées sur CM5 essensys-gateway @ 192.168.0.14 (2026-05-31)
  services.essensys = {
    enable = true;

    platform.cm5.enable = true;

    gateway = {
      enable = true;
      eth0Mac = "88:a2:9e:34:27:61";
      eth1Mac = "00:e0:4c:68:01:be";
      eth1Address = "10.0.1.1";
      eth1Prefix = 24;
      eth0Address = "192.168.0.14";
      armoireHostname = "mon.essensys.fr";
      dhcpRangeStart = "10.0.1.100";
      dhcpRangeEnd = "10.0.1.200";
    };

    nvme = {
      enable = true;
      device = "/dev/disk/by-label/essensys-data";
      mountPoint = "/mnt/nvme";
      required = true;
    };

    nginx.enable = true;
    frontend.enable = true;
    backend.enable = false; # enable when image/package ready
    traefik.enable = false; # enable after ACME/secrets configured
    redis.enable = true;
    mosquitto.enable = true;
  };

  networking.hostName = "essensys-gateway";

  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPNEyP1+K6ieKTFxgxu0VedxZbByRUpw1vHjnyujyo/8 nrineau@Nicolass-Mac-mini.local"
  ];

  users.users.essensys = {
    isNormalUser = true;
    group = "essensys";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPNEyP1+K6ieKTFxgxu0VedxZbByRUpw1vHjnyujyo/8 nrineau@Nicolass-Mac-mini.local"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    curl
    dig
    ethtool
    iproute2
    nvme-cli
  ];

  system.stateVersion = "24.11";
}
