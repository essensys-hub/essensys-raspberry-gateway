{
  config,
  lib,
  ...
}:
let
  cfg = config.services.essensys;
in
{
  options.services.essensys.redis = {
    enable = lib.mkEnableOption "Redis for Essensys backend";
  };

  config = lib.mkIf (cfg.enable && cfg.redis.enable) {
    services.redis.servers."" = {
      enable = true;
      bind = "127.0.0.1";
      port = 6379;
      settings = {
        dir = lib.mkForce "${cfg.dataDir}/redis";
        databases = 16;
      };
    };
  };
}
