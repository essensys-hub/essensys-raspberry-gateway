## ADDED Requirements

### Requirement: NixOS module for Essensys Nginx
The system SHALL provide `services.essensys.nginx` (or equivalent) enabling Nginx with configuration derived from the `essensys-nginx` repository files.

#### Scenario: Module enables nginx service
- **WHEN** `services.essensys.nginx.enable = true` and `nixos-rebuild switch` completes
- **THEN** `systemctl is-active nginx` returns `active`

#### Scenario: Config sourced from essensys-nginx
- **WHEN** inspecting the Nix module implementation
- **THEN** it references `essensys-nginx` via flake input, `fetchFromGitHub`, or documented local path override

### Requirement: Gateway listen addresses on eth1
In gateway profile, Nginx SHALL listen for the armoire server block on `eth1_ip:80` only, not on all interfaces.

#### Scenario: Nginx bound to eth1 for armoire traffic
- **WHEN** `ss -tlnp` is run after activation
- **THEN** the armoire Nginx listener is bound to the eth1 IP on port 80

### Requirement: HTTP rejected on eth0 port 80
In gateway profile, Nginx SHALL reject or close connections for HTTP on `eth0_ip:80` (e.g. `return 444`) so armoire vhosts are not exposed on the LAN interface.

#### Scenario: eth0 HTTP rejected
- **WHEN** `curl -v http://<eth0_ip>/` is executed from the LAN
- **THEN** the connection is closed without serving armoire content

### Requirement: BP_MQX_ETH API proxy compatibility
The `/api/` location SHALL proxy to the backend with buffering enabled, gzip disabled for API responses, and buffer sizes matching the Ansible gateway template requirements for legacy single-packet TCP clients.

#### Scenario: API proxy settings present
- **WHEN** the generated Nginx configuration is inspected
- **THEN** `/api/` includes `proxy_buffering on`, `gzip off`, and explicit proxy buffer size directives

#### Scenario: API reachable from armoire segment
- **WHEN** a client on eth1 requests `http://mon.essensys.fr/api/` (or eth1 IP equivalent)
- **THEN** the request is proxied to the backend listener on localhost port 7070

### Requirement: Frontend and auxiliary routes
Nginx SHALL serve static frontend assets at `/` and proxy `/mcp/` and `/admin/` to configured localhost ports when those services are enabled.

#### Scenario: SPA routing
- **WHEN** a request for a non-file path is made to `/`
- **THEN** Nginx serves `index.html` for SPA routing per `essensys-nginx` conventions
