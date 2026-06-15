{
  config,
  lib,
  ...
}:
let
  cfg = config.services.essensys;
  gw = cfg.gateway;
in
{
  options.services.essensys.adguard = {
    enable = lib.mkEnableOption "AdGuard Home DNS on LAN (eth0) — optional, disabled by default";
  };

  options.services.essensys.prometheus = {
    enable = lib.mkEnableOption "Prometheus monitoring — optional stub";
  };

  options.services.essensys.mcp = {
    enable = lib.mkEnableOption "Essensys MCP server — optional stub";
  };

  config = {
    # TODO: wire nixpkgs AdGuard Home module when production-ready.
    # When enabled, bind DNS to eth0 only to avoid conflict with dnsmasq on eth1.
    assertions = lib.mkIf (cfg.enable && cfg.adguard.enable && gw.enable) [
      {
        assertion = gw.eth0Address != null;
        message = "services.essensys.adguard on dual-NIC gateway requires eth0Address for bind separation from dnsmasq.";
      }
    ];

    # TODO: services.prometheus when enable = true
    # TODO: essensys MCP systemd service on port 8083 when enable = true
  };
}
