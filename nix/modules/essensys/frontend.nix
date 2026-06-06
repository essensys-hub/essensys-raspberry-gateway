{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.essensys;
  frontend = cfg.frontend;

  placeholder = pkgs.writeText "index.html" ''
    <!DOCTYPE html>
    <html><head><title>Essensys Gateway</title></head>
    <body><p>Essensys frontend placeholder — set services.essensys.frontend.package.</p></body></html>
  '';
in
{
  options.services.essensys.frontend = {
    enable = lib.mkEnableOption "Essensys React frontend static assets";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Frontend derivation; null uses placeholder index.html.";
    };
  };

  config = lib.mkIf (cfg.enable && frontend.enable) {
    systemd.tmpfiles.rules = [
      "d ${config.services.essensys.nginx.frontendRoot} 0755 ${cfg.user} ${cfg.user} - -"
    ];

    system.activationScripts.essensysFrontend = ''
      mkdir -p ${config.services.essensys.nginx.frontendRoot}
      ${
        if frontend.package != null then
          "cp -a ${frontend.package}/* ${config.services.essensys.nginx.frontendRoot}/"
        else
          "cp ${placeholder} ${config.services.essensys.nginx.frontendRoot}/index.html"
      }
    '';
  };
}
