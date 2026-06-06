## ADDED Requirements

### Requirement: Traefik HTTPS bound to eth0
In gateway profile, Traefik SHALL bind the TLS entrypoint (`websecure` or equivalent) to `eth0_ip:443`, not all interfaces.

#### Scenario: Traefik on eth0 only
- **WHEN** `ss -tlnp` is run after activation
- **THEN** Traefik listens on `eth0_ip:443` for HTTPS

#### Scenario: No Traefik HTTPS on eth1
- **WHEN** `ss -tlnp` is run
- **THEN** port 443 is not bound on the eth1 IP address

### Requirement: Nginx HTTP armoire path not on eth0
Nginx armoire HTTP (port 80) SHALL NOT serve the armoire profile on eth0; only eth1 (and localhost if explicitly allowed) per `nix-essensys-nginx` spec.

#### Scenario: Port 80 armoire listener isolated
- **WHEN** scanning listeners on eth0
- **THEN** no Nginx server block serving armoire/API legacy path listens on eth0:80 except the explicit reject/catch-all block

### Requirement: LAN user access via HTTPS on eth0
Users on the LAN SHALL reach the frontend over HTTPS on eth0 port 443 when Traefik and frontend modules are enabled.

#### Scenario: LAN HTTPS frontend
- **WHEN** `curl -k https://<eth0_ip>/` is executed from the LAN
- **THEN** the response is the Essensys frontend (HTTP 200 or valid redirect), not connection refused
