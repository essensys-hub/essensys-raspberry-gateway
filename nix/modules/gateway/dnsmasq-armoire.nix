{
  config,
  lib,
  ...
}:
let
  cfg = config.services.essensys;
  gw = cfg.gateway;

  reservationLines = lib.concatLines (
    map (
      r:
      if r.hostname != null then
        "dhcp-host=${r.mac},${r.address},${r.hostname},infinite"
      else
        "dhcp-host=${r.mac},${r.address},,infinite"
    ) gw.dhcpReservations
  );
in
{
  config = lib.mkIf (cfg.enable && gw.enable) {
    services.dnsmasq = {
      enable = true;
      settings = {
        "bind-interfaces" = true;
        interface = [ "eth1" ];
        "listen-address" = [ "127.0.0.1" gw.eth1Address ];
        "no-dhcp-interface" = [ "eth0" ];
        "dhcp-range" = [
          "${gw.dhcpRangeStart},${gw.dhcpRangeEnd},${gw.dhcpLeaseTime}"
        ];
        "dhcp-option" = [
          "option:dns-server,${gw.eth1Address}"
          "option:router,${gw.eth1Address}"
        ];
        address = [
          "/${gw.armoireHostname}/${gw.eth1Address}"
        ];
        server = [ "1.1.1.1" "8.8.8.8" ];
      };
    };

    # Extra dnsmasq config for static reservations
    environment.etc."dnsmasq.d/essensys-armoire-reservations.conf".text =
      lib.optionalString (gw.dhcpReservations != [ ]) reservationLines;

    # AdGuard (optional) must not bind 0.0.0.0:53 when enabled — see optional-services.nix
    networking.firewall.allowedUDPPorts = lib.mkAfter [ 67 ];
  };
}
