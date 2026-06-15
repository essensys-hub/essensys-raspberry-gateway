## ADDED Requirements

### Requirement: eth0 configured as LAN DHCP client
The gateway SHALL configure `eth0` as a DHCP client that obtains an IP address from the upstream LAN router. The configuration SHALL be implemented using systemd-networkd `.network` unit files. The interface SHALL be matched by its MAC address to guarantee stable assignment across reboots and kernel upgrades.

#### Scenario: eth0 receives IP from LAN DHCP
- **WHEN** the gateway boots with eth0 connected to the LAN
- **THEN** `ip addr show eth0` displays a valid IP address obtained from the upstream LAN DHCP server within 30 seconds

#### Scenario: eth0 configuration survives reboot
- **WHEN** the gateway is rebooted
- **THEN** eth0 obtains a new DHCP lease and `systemctl is-active systemd-networkd` returns `active`

### Requirement: eth1 configured with static IPv4 address
The gateway SHALL configure `eth1` with a static IPv4 address from an RFC1918 subnet (e.g., `10.0.1.1/24`) as defined by the `gateway_eth1_ip` and `gateway_eth1_prefix` Ansible variables. The configuration SHALL use systemd-networkd and match the interface by MAC address (`gateway_eth1_mac` variable).

#### Scenario: eth1 has static IP after configuration
- **WHEN** the Ansible role `raspberry_gateway_network` has been applied
- **THEN** `ip addr show eth1` shows the IP address matching `gateway_eth1_ip/gateway_eth1_prefix`

#### Scenario: eth1 static IP persists across reboots
- **WHEN** the gateway is rebooted
- **THEN** `ip addr show eth1` still shows the configured static IP without requiring any manual intervention

#### Scenario: eth1 does not have a default route
- **WHEN** the gateway is fully booted
- **THEN** `ip route` shows a default route only via eth0 and no default route via eth1

### Requirement: Network configuration is idempotent
The `raspberry_gateway_network` Ansible role SHALL be idempotent: running it multiple times on the same host SHALL produce the same systemd-networkd unit files and SHALL restart `systemd-networkd` only when the files have changed.

#### Scenario: No restart on unchanged config
- **WHEN** the role is applied twice without changing any variable
- **THEN** the second run reports no changes and `systemd-networkd` is not restarted

#### Scenario: Restart on changed IP
- **WHEN** `gateway_eth1_ip` is changed and the role is re-applied
- **THEN** the `.network` unit file is updated and `systemd-networkd` is restarted via the Ansible handler

### Requirement: Existing network files are backed up before replacement
Before overwriting any systemd-networkd unit file, the role SHALL create a timestamped backup of the existing file in the same directory (e.g., `10-eth1.network.bak-<timestamp>`).

#### Scenario: Backup created on first apply
- **WHEN** a `.network` file already exists and the role is applied
- **THEN** a backup file with a `.bak-*` suffix exists alongside the new file

### Requirement: Non-gateway deployment unaffected
When `gateway_dual_nic` is `false` (default), the `raspberry_gateway_network` role SHALL NOT be executed and no systemd-networkd unit files SHALL be deployed by the gateway roles.

#### Scenario: Standard deployment skips network role
- **WHEN** `install.raspberrypi.yml` is run with default variables (`gateway_dual_nic: false`)
- **THEN** no file under `/etc/systemd/network/` is created or modified by the gateway role
