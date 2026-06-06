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
  config = lib.mkIf (cfg.enable && gw.enable) {
    networking.useNetworkd = true;
    networking.useDHCP = lib.mkForce false;
    systemd.network.enable = true;

    systemd.network.wait-online.enable = true;
    systemd.network.wait-online.anyInterface = false;

    systemd.network.networks."10-essensys-eth0" = {
      matchConfig.MACAddress = gw.eth0Mac;
      networkConfig = lib.mkMerge [
        (lib.mkIf (gw.eth0Address == null) {
          DHCP = "ipv4";
        })
        (lib.mkIf (gw.eth0Address != null) {
          DHCP = "no";
          Address = [ "${gw.eth0Address}/${toString 24}" ];
        })
      ];
      linkConfig.RequiredForOnline = "routable";
    };

    systemd.network.networks."20-essensys-eth1" = {
      matchConfig.MACAddress = gw.eth1Mac;
      networkConfig = {
        DHCP = "no";
        Address = [ "${gw.eth1Address}/${toString gw.eth1Prefix}" ];
      };
      linkConfig.RequiredForOnline = "carrier";
      # No default route on armoire segment
      routes = [ ];
    };
  };
}
