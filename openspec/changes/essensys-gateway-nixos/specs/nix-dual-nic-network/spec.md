## ADDED Requirements

### Requirement: eth0 configured as LAN DHCP client via systemd-networkd
The gateway NixOS configuration SHALL configure `eth0` as a DHCP client using systemd-networkd. The interface SHALL be matched by MAC address for stable naming across reboots.

#### Scenario: eth0 obtains LAN address
- **WHEN** the gateway boots with eth0 connected to the LAN
- **THEN** `ip addr show eth0` displays an IPv4 address within 30 seconds

#### Scenario: eth0 configuration persists after reboot
- **WHEN** the gateway reboots
- **THEN** eth0 obtains a DHCP lease and `networkctl status eth0` reports a configured routable address

### Requirement: eth1 configured with static RFC1918 address
The gateway SHALL configure `eth1` with a static IPv4 address and prefix from NixOS options (e.g. `services.essensys.gateway.eth1Address`). The interface SHALL be matched by MAC address.

#### Scenario: eth1 static IP applied
- **WHEN** the NixOS configuration is activated on hardware
- **THEN** `ip addr show eth1` shows the configured static address

#### Scenario: No default route via eth1
- **WHEN** the gateway is fully booted
- **THEN** `ip route` shows the default route only via eth0, not eth1

### Requirement: Network configuration is declarative and rebuild-safe
Changes to network options SHALL take effect via `nixos-rebuild switch` without manual editing of `/etc/systemd/network/` outside Nix-managed files.

#### Scenario: IP change via Nix option
- **WHEN** `services.essensys.gateway.eth1Address` is changed and `nixos-rebuild switch` runs
- **THEN** eth1 reflects the new address after networkd reload or reboot
