{
  config,
  lib,
  ...
}:
let
  cfg = config.services.essensys;
in
{
  options.services.essensys.mosquitto = {
    enable = lib.mkEnableOption "Mosquitto MQTT broker for Essensys";
  };

  config = lib.mkIf (cfg.enable && cfg.mosquitto.enable) {
    services.mosquitto = {
      enable = true;
      listeners = [
        { address = "127.0.0.1"; port = 1883; }
      ];
    };

    systemd.services.mosquitto.preStart = lib.mkAfter ''
      mkdir -p ${cfg.dataDir}/mosquitto
    '';
  };
}
