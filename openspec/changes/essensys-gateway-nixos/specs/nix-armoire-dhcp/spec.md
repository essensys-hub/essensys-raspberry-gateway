## ADDED Requirements

### Requirement: DHCP server active only on eth1
The gateway SHALL run a DHCP server (dnsmasq or equivalent) bound exclusively to the eth1 interface/subnet. It SHALL NOT offer DHCP leases on eth0 or the upstream LAN.

#### Scenario: DHCP lease on armoire segment
- **WHEN** a client connects to eth1 and requests DHCP
- **THEN** it receives an IPv4 address from the configured pool within the eth1 subnet

#### Scenario: No DHCP on eth0
- **WHEN** a client on the LAN connected to eth0 sends DHCP discover
- **THEN** the gateway does not respond with a DHCP offer from the armoire DHCP service

### Requirement: Configurable pool and reservations
DHCP range start/end, lease time, and static reservations SHALL be configurable via NixOS module options and rendered into the dnsmasq configuration.

#### Scenario: Static reservation honored
- **WHEN** a MAC address is listed in `services.essensys.gateway.dhcpReservations`
- **THEN** that client always receives the reserved IPv4 address on eth1

### Requirement: dnsmasq binds to eth1 address only
The DHCP/DNS service on eth1 SHALL use `bind-interfaces` (or equivalent) and listen only on the eth1 gateway IP to avoid conflicting with LAN DNS services.

#### Scenario: dnsmasq listen address scoped
- **WHEN** `ss -ulnp` is run after activation
- **THEN** dnsmasq on port 67/53 is bound to the eth1 IP, not `0.0.0.0` on all interfaces
