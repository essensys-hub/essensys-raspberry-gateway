## ADDED Requirements

### Requirement: Nginx listens on eth1 IP port 80 for armoire traffic
When `gateway_dual_nic` is `true`, the Nginx `server` block serving the armoire API path (legacy BP_MQX_ETH) SHALL use `listen {{ gateway_eth1_ip }}:80;` exclusively. This ensures armoire HTTP traffic is handled by the correct virtual host and does not bleed onto the LAN interface.

#### Scenario: Nginx accepts HTTP on eth1:80
- **WHEN** an armoire device sends an HTTP request to `gateway_eth1_ip:80`
- **THEN** Nginx returns a valid response (2xx or expected API response) and the request is logged

#### Scenario: Nginx does not serve armoire vhost on eth0:80
- **WHEN** a LAN device sends an HTTP request to `gateway_eth0_ip:80`
- **THEN** Nginx returns a 444 (connection closed) or redirects to HTTPS — NOT the armoire server block content

### Requirement: Traefik listens on eth0 IP port 443 for user HTTPS frontend
When `gateway_dual_nic` is `true`, the Traefik `websecure` entrypoint SHALL bind to `{{ gateway_eth0_ip }}:443`. The armoire segment clients on eth1 SHALL NOT be able to reach the Traefik HTTPS frontend on port 443.

#### Scenario: LAN user accesses HTTPS frontend
- **WHEN** a LAN user sends an HTTPS request to `gateway_eth0_ip:443`
- **THEN** Traefik responds with the expected frontend (TLS handshake succeeds, HTTP 200 or appropriate response)

#### Scenario: Traefik not reachable from eth1 on 443
- **WHEN** an armoire device attempts to connect to `gateway_eth1_ip:443`
- **THEN** the connection is refused (no listener on eth1:443)

### Requirement: Traefik armoire HTTP entrypoint bound to eth1:80
When `gateway_dual_nic` is `true`, Traefik SHALL expose an additional entrypoint `armoire` bound to `{{ gateway_eth1_ip }}:80` for forwarding armoire API traffic to the backend. This entrypoint SHALL NOT be exposed on eth0.

#### Scenario: Traefik forwards armoire HTTP via eth1 entrypoint
- **WHEN** an HTTP request arrives on `gateway_eth1_ip:80`
- **THEN** Traefik (or Nginx, depending on final routing decision) routes the request to the correct backend service

### Requirement: Default (single-NIC) binding preserved when gateway_dual_nic is false
When `gateway_dual_nic` is `false`, Nginx and Traefik templates SHALL fall back to `0.0.0.0` (all interfaces) or the existing default configuration, preserving current behavior.

#### Scenario: Standard deployment uses default bind address
- **WHEN** `gateway_dual_nic: false` and `install.raspberrypi.yml` is applied
- **THEN** Nginx listens on `0.0.0.0:80` (or current default) and Traefik on `0.0.0.0:443` as before

### Requirement: AdGuard admin UI not reachable from eth1
When `gateway_dual_nic` is `true`, the AdGuard Home web interface (default port 3000 or configured port) SHALL NOT be accessible from the eth1 (armoire) subnet. Firewall rules (iptables/nftables) or bind address restriction SHALL enforce this.

#### Scenario: AdGuard admin blocked from armoire segment
- **WHEN** an armoire device attempts to access the AdGuard web UI port from eth1
- **THEN** the connection is refused or timed out

### Requirement: Port binding configuration is generated from Ansible variables
All listen addresses in Nginx and Traefik templates SHALL reference `gateway_eth0_ip` and `gateway_eth1_ip` variables. Hard-coded IPs SHALL NOT appear in templates.

#### Scenario: IP change propagates to all templates
- **WHEN** `gateway_eth1_ip` is changed and all affected roles are re-run
- **THEN** `grep -r 'gateway_eth1_ip_value' /etc/nginx /etc/traefik` shows the new IP in all config files
