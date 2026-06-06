## ADDED Requirements

### Requirement: Split-DNS for mon.essensys.fr on eth1
Clients using the gateway as DNS on the eth1 segment SHALL resolve `mon.essensys.fr` to the gateway's eth1 IPv4 address.

#### Scenario: Armoire segment DNS resolution
- **WHEN** a client on eth1 queries `mon.essensys.fr` against the gateway DNS on eth1
- **THEN** the response A record equals the configured eth1 gateway IP

#### Scenario: LAN clients unaffected
- **WHEN** a client on eth0 resolves `mon.essensys.fr` via upstream/LAN DNS
- **THEN** the eth1 rewrite rule does not break normal upstream resolution unless explicitly configured for eth0

### Requirement: DNS rewrite configurable
The armoire hostname and target IP SHALL be configurable via NixOS options (defaults: `mon.essensys.fr` → eth1 IP).

#### Scenario: Custom hostname option
- **WHEN** `services.essensys.gateway.armoireHostname` is set to a test hostname
- **THEN** dnsmasq serves that hostname pointing to the eth1 IP for eth1 clients
