## ADDED Requirements

### Requirement: mon.essensys.fr resolves to gateway eth1 IP on the armoire segment
On the eth1 (armoire) segment, DNS queries for `mon.essensys.fr` SHALL return the gateway's eth1 IP address (`gateway_eth1_ip`). This SHALL be implemented via a dnsmasq `address=/mon.essensys.fr/<gateway_eth1_ip>` directive served on the eth1 interface.

#### Scenario: Armoire client resolves mon.essensys.fr to eth1 IP
- **WHEN** an armoire device sends a DNS query for `mon.essensys.fr` to the gateway's eth1 IP on port 53
- **THEN** the response contains an A record pointing to `gateway_eth1_ip`

#### Scenario: Resolution works without internet connectivity
- **WHEN** the armoire segment has no upstream internet access
- **THEN** `dig mon.essensys.fr @{{ gateway_eth1_ip }}` still resolves to `gateway_eth1_ip`

### Requirement: LAN DNS for mon.essensys.fr unaffected
On the LAN (eth0) side, DNS resolution for `mon.essensys.fr` SHALL follow the upstream / AdGuard path unchanged. The gateway SHALL NOT inject the private eth1 address into eth0 DNS responses.

#### Scenario: LAN client resolves mon.essensys.fr via upstream
- **WHEN** a LAN device queries AdGuard (eth0) for `mon.essensys.fr`
- **THEN** the response is the public or upstream-configured address, NOT `gateway_eth1_ip`

### Requirement: Upstream DNS forwarding for all other names on armoire segment
For DNS queries on eth1 that are NOT for `mon.essensys.fr`, dnsmasq SHALL forward the query to the upstream DNS servers (inherited from the eth0 interface / resolv.conf or explicitly configured via `gateway_upstream_dns` variable).

#### Scenario: Armoire client resolves an external domain
- **WHEN** an armoire device queries for `example.com` via the gateway eth1 DNS
- **THEN** the gateway forwards the query upstream and returns the resolved address

### Requirement: DHCP advertises gateway as DNS server for eth1 clients
The dnsmasq DHCP server SHALL include a DHCP option 6 (DNS server) pointing to `gateway_eth1_ip` in all DHCP responses on eth1. This ensures armoire clients automatically use the gateway for DNS resolution.

#### Scenario: DHCP lease includes DNS server option
- **WHEN** an armoire device receives a DHCP lease
- **THEN** the lease includes DNS server option pointing to `gateway_eth1_ip`

#### Scenario: Armoire client can resolve mon.essensys.fr after DHCP
- **WHEN** an armoire device has received a DHCP lease from the gateway
- **THEN** it can resolve `mon.essensys.fr` without manual DNS configuration

### Requirement: Split-DNS hostname configurable via variable
The hostname subject to rewriting SHALL be configurable via the `gateway_armoire_hostname` variable (default: `mon.essensys.fr`). The dnsmasq template SHALL use this variable for the `address=` directive.

#### Scenario: Custom hostname resolves to eth1 IP
- **WHEN** `gateway_armoire_hostname` is set to a custom value and the role is applied
- **THEN** DNS queries for that hostname on eth1 return `gateway_eth1_ip`
