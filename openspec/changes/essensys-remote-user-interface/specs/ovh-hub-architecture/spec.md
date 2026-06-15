## ADDED Requirements

### Requirement: Single OVH VPS hosts support and portal services
The system SHALL deploy the user domotic portal on the **same OVH VPS** already running `essensys-support-site`, using the public URL **`https://mon.essensys.fr`**. No separate VPS SHALL be provisioned for MVP.

#### Scenario: Portal and support share host
- **WHEN** `support-site.yml` is applied with portal roles enabled
- **THEN** Nginx on the VPS serves both the existing support-site frontend and `/portal/` static assets from the same machine

### Requirement: HTTPS port 443 for all WAN cloud traffic
All browser-to-OVH and gateway-to-OVH API traffic SHALL use **TLS on port 443**. The gateway cloud agent SHALL NOT call `http://mon.essensys.fr` for hub communication.

#### Scenario: Gateway agent uses HTTPS only
- **WHEN** the cloud sync agent is configured with `hub_url: https://mon.essensys.fr`
- **THEN** all poll, heartbeat, and done requests use HTTPS and appear in logs without plain HTTP URLs to the hub

### Requirement: HTTP port 80 remains local armoire only
HTTP on port 80 for BP_MQX_ETH SHALL remain on the **local gateway eth1 segment** only and SHALL NOT be exposed as the WAN transport to OVH.

#### Scenario: Firmware polls local backend
- **WHEN** BP_MQX_ETH requests `GET /api/myactions`
- **THEN** the request is served by the local gateway backend on the armoire network, not by the OVH VPS directly
