{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.essensys;
  traefik = cfg.traefik;
  gw = cfg.gateway;

  eth0Bind =
    if gw.enable && gw.bindStrict && gw.eth0Address != null then
      gw.eth0Address
    else
      "0.0.0.0";
in
{
  options.services.essensys.traefik = {
    enable = lib.mkEnableOption "Traefik TLS reverse proxy for user HTTPS (eth0)";

    acmeEmail = lib.mkOption {
      type = lib.types.str;
      default = "admin@essensys.local";
      description = "ACME email — use agenix/sops-nix in production.";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      default = "essensys.local";
    };
  };

  config = lib.mkIf (cfg.enable && traefik.enable) {
    services.traefik = {
      enable = true;
      staticConfigOptions = {
        entryPoints.websecure.address = "${eth0Bind}:443";
        certificatesResolvers.letsencrypt.acme = {
          email = traefik.acmeEmail;
          storage = "/var/lib/traefik/acme.json";
          httpChallenge.entryPoint = "websecure";
        };
        providers.file = {
          directory = "/etc/traefik/dynamic";
          watch = true;
        };
      };
    };

    environment.etc."traefik/dynamic/frontend.yaml".text = ''
      http:
        routers:
          essensys-frontend:
            rule: "Host(`${traefik.domain}`)"
            entryPoints:
              - websecure
            service: essensys-frontend
            tls:
              certResolver: letsencrypt
        services:
          essensys-frontend:
            loadBalancer:
              servers:
                - url: "http://127.0.0.1:80"
    '';

    systemd.services.traefik.preStart = lib.mkAfter ''
      mkdir -p /var/lib/traefik
    '';

    networking.firewall.allowedTCPPorts = lib.mkAfter [ 443 ];
  };
}
