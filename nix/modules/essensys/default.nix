{
  config,
  lib,
  ...
}:
let
  cfg = config.services.essensys;
in
{
  options.services.essensys = {
    enable = lib.mkEnableOption "Essensys gateway application stack";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/nvme/data";
      description = "Root directory for Essensys mutable data (NVMe-backed).";
    };

    logDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/nvme/logs";
      description = "Directory for Essensys application logs.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "essensys";
      description = "System user owning Essensys data files.";
    };

    gateway = {
      enable = lib.mkEnableOption "dual-NIC gateway profile (eth0 LAN, eth1 armoire bus)";

      eth0Mac = lib.mkOption {
        type = lib.types.str;
        example = "dc:a6:32:12:34:56";
        description = "MAC address of eth0 (LAN). Used for stable systemd-networkd matching.";
      };

      eth1Mac = lib.mkOption {
        type = lib.types.str;
        example = "00:e0:4c:68:00:01";
        description = "MAC address of eth1 (armoire segment, USB RTL8153 on Essensys IO board).";
      };

      eth0Address = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "192.168.1.50";
        description = ''
          Optional static IPv4 for eth0. When null, eth0 uses DHCP.
          When set, used for strict Traefik/Nginx bind addresses on the LAN interface.
          For DHCP eth0, set this to the reserved LAN address or leave null and use
          services.essensys.gateway.bindStrict = false.
        '';
      };

      eth1Address = lib.mkOption {
        type = lib.types.str;
        default = "10.0.1.1";
        description = "Static IPv4 address of the gateway on the armoire segment (eth1).";
      };

      eth1Prefix = lib.mkOption {
        type = lib.types.int;
        default = 24;
        description = "Prefix length for eth1 static address.";
      };

      armoireHostname = lib.mkOption {
        type = lib.types.str;
        default = "mon.essensys.fr";
        description = "Hostname rewritten to eth1Address for armoire-segment DNS clients.";
      };

      bindStrict = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          When true, Nginx and Traefik bind to configured eth0/eth1 addresses only.
          Requires eth0Address when Traefik is enabled and eth0 uses static addressing.
        '';
      };

      dhcpRangeStart = lib.mkOption {
        type = lib.types.str;
        default = "10.0.1.100";
      };

      dhcpRangeEnd = lib.mkOption {
        type = lib.types.str;
        default = "10.0.1.200";
      };

      dhcpLeaseTime = lib.mkOption {
        type = lib.types.str;
        default = "12h";
      };

      dhcpReservations = lib.mkOption {
        type = lib.types.listOf (
          lib.types.submodule {
            options = {
              mac = lib.mkOption { type = lib.types.str; };
              address = lib.mkOption { type = lib.types.str; };
              hostname = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
              };
            };
          }
        );
        default = [ ];
        description = "Static DHCP reservations on eth1.";
      };
    };

    nvme = {
      enable = lib.mkEnableOption "NVMe data partition mount and layout";

      device = lib.mkOption {
        type = lib.types.str;
        default = "/dev/disk/by-partlabel/essensys-nvme";
        description = "Block device or partition for NVMe data (ext4).";
      };

      mountPoint = lib.mkOption {
        type = lib.types.str;
        default = "/mnt/nvme";
      };

      required = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "When true, boot fails if NVMe is not mountable.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.user;
      home = "/var/lib/${cfg.user}";
      createHome = true;
    };
    users.groups.${cfg.user} = { };

    systemd.services.nginx = lib.mkIf config.services.essensys.nginx.enable {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };

    systemd.services.traefik = lib.mkIf config.services.essensys.traefik.enable {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };
  };
}
