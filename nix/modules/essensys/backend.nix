{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.essensys;
  backend = cfg.backend;
in
{
  options.services.essensys.backend = {
    enable = lib.mkEnableOption "Essensys Go backend API";

    port = lib.mkOption {
      type = lib.types.port;
      default = 7070;
    };

    # v1: OCI image with host networking (parity with Ansible Docker stack)
    ociImage = lib.mkOption {
      type = lib.types.str;
      default = "essensyshub/essensys-backend:latest";
      description = "Container image when package is null.";
    };

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Native backend package; when null, uses OCI container (if docker enabled).";
    };
  };

  config = lib.mkIf (cfg.enable && backend.enable) {
    virtualisation.docker.enable = lib.mkIf (backend.package == null) true;

    systemd.services.essensys-backend =
      if backend.package != null then
        {
          description = "Essensys backend API";
          wantedBy = [ "multi-user.target" ];
          after = [
            "network.target"
            "redis.service"
          ];
          serviceConfig = {
            Type = "simple";
            User = cfg.user;
            Group = cfg.user;
            WorkingDirectory = cfg.dataDir;
            ExecStart = "${backend.package}/bin/essensys-backend -port ${toString backend.port}";
            Restart = "on-failure";
          };
        }
      else
        {
          description = "Essensys backend API (OCI, host network)";
          wantedBy = [ "multi-user.target" ];
          after = [
            "docker.service"
            "network-online.target"
          ];
          requires = [ "docker.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStartPre = "-${pkgs.docker}/bin/docker pull ${backend.ociImage}";
            ExecStart = ''
              ${pkgs.docker}/bin/docker run --rm -d --name essensys-backend \
                --network host \
                -v ${cfg.dataDir}:/opt/data \
                ${backend.ociImage}
            '';
            ExecStop = "${pkgs.docker}/bin/docker stop essensys-backend";
          };
        };

    networking.firewall.allowedTCPPorts = lib.mkAfter [ backend.port ];
  };
}
