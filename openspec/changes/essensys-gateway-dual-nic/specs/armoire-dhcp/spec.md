## ADDED Requirements

### Requirement: DHCP server active exclusively on eth1
The gateway SHALL run a `dnsmasq` DHCP server that issues leases only on the `eth1` interface. The server SHALL be configured with `interface=eth1` and `bind-interfaces` directives so that it does not answer DHCP requests arriving on eth0 or any other interface.

#### Scenario: DHCP offer sent to armoire client on eth1
- **WHEN** an armoire device connected to eth1 sends a DHCP DISCOVER broadcast
- **THEN** the gateway sends a DHCP OFFER with an IP from the configured range (`gateway_dhcp_range_start` to `gateway_dhcp_range_end`)

#### Scenario: DHCP server does not respond to requests on eth0
- **WHEN** a device on the LAN (eth0) sends a DHCP DISCOVER
- **THEN** the gateway's dnsmasq does NOT respond (the upstream LAN DHCP server handles it)

### Requirement: DHCP lease range configurable via Ansible variables
The DHCP pool SHALL be defined by the variables `gateway_dhcp_range_start`, `gateway_dhcp_range_end`, and `gateway_dhcp_lease_time`. These SHALL be the single source of truth; the dnsmasq configuration file SHALL be generated from an Ansible template.

#### Scenario: Lease issued within configured range
- **WHEN** an armoire device requests a lease
- **THEN** the assigned IP is within [`gateway_dhcp_range_start`, `gateway_dhcp_range_end`]

#### Scenario: Lease duration matches configured value
- **WHEN** a lease is issued
- **THEN** the lease time matches `gateway_dhcp_lease_time`

### Requirement: Static DHCP reservations supported via Ansible variables
The role SHALL support a list of static MAC-to-IP reservations defined in `gateway_dhcp_reservations` (a list of `{mac, ip, name}` dicts). Each entry SHALL generate a `dhcp-host=<mac>,<ip>,<name>` dnsmasq directive.

#### Scenario: Reserved device always gets the same IP
- **WHEN** a device with a MAC address listed in `gateway_dhcp_reservations` requests a lease
- **THEN** it receives the IP address specified in the reservation

### Requirement: dnsmasq does not conflict with AdGuard on DNS port 53
dnsmasq's DNS listener SHALL be bound exclusively to `gateway_eth1_ip` on port 53 (`listen-address={{ gateway_eth1_ip }}`, `bind-interfaces`). AdGuard SHALL continue to serve DNS on eth0 (or loopback). No port 53 conflict SHALL occur on any interface.

#### Scenario: dnsmasq DNS only on eth1
- **WHEN** the gateway is fully configured
- **THEN** `ss -tlnup | grep ':53'` shows dnsmasq bound to `gateway_eth1_ip:53` and AdGuard/systemd-resolved bound to eth0 or loopback — not both on the same address

### Requirement: dnsmasq service managed by systemd and enabled at boot
The dnsmasq service SHALL be enabled and started via the Ansible `service` module. The role SHALL ensure dnsmasq starts after `network-online.target` and after the eth1 interface is up.

#### Scenario: dnsmasq starts after reboot
- **WHEN** the gateway reboots
- **THEN** `systemctl is-active dnsmasq` returns `active` once eth1 is up

### Requirement: DHCP role idempotent
Running the `raspberry_gateway_dhcp` role multiple times SHALL produce no changes if variables have not changed.

#### Scenario: No change on second run
- **WHEN** the role is applied twice with identical variables
- **THEN** Ansible reports no tasks changed on the second run
