{
  config,
  lib,
  ...
}:
let
  cfg = config.services.essensys;
  nvme = cfg.nvme;
  subdirs = [
    "data"
    "logs"
    "prometheus"
    "redis"
    "mosquitto"
  ];
in
{
  config = lib.mkIf (cfg.enable && nvme.enable) {
    fileSystems.${nvme.mountPoint} = {
      device = nvme.device;
      fsType = "ext4";
      options = [
        "noatime"
        "defaults"
      ];
      neededForBoot = nvme.required;
    };

    systemd.tmpfiles.rules =
      (map (
        d: "d ${nvme.mountPoint}/${d} 0755 ${cfg.user} ${cfg.user} - -"
      ) subdirs)
      ++ [
        "d ${cfg.logDir} 0755 ${cfg.user} ${cfg.user} - -"
      ];

    # Fail early with a clear message when NVMe is required but missing
    systemd.services.essensys-nvme-check = lib.mkIf nvme.required {
      description = "Verify Essensys NVMe data volume is present";
      wantedBy = [ "multi-user.target" ];
      before = [
        "redis.service"
        "mosquitto.service"
        "essensys-backend.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        if [ ! -e "${nvme.device}" ]; then
          echo "ERROR: NVMe device ${nvme.device} not found. Enable PCIe/NVMe in CM5 firmware or set services.essensys.nvme.required = false for degraded mode." >&2
          exit 1
        fi
        if ! findmnt -rn -T ${nvme.mountPoint} >/dev/null 2>&1; then
          echo "ERROR: ${nvme.mountPoint} is not mounted." >&2
          exit 1
        fi
      '';
    };
  };
}
