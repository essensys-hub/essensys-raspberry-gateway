## ADDED Requirements

### Requirement: Gateway agent polls pending actions over HTTPS
The edge cloud sync module SHALL periodically call `GET https://mon.essensys.fr/api/gateway/pending-actions` with header `Authorization: Bearer <gateway_token>`.

#### Scenario: Successful poll with token
- **WHEN** cloud sync is enabled with a valid gateway token
- **THEN** the agent receives a JSON list of pending cloud actions over HTTPS

#### Scenario: Invalid token rejected
- **WHEN** the agent uses an invalid or missing token
- **THEN** the hub responds with HTTP 401

### Requirement: Agent applies actions locally via ActionService
For each fetched action, the agent SHALL apply the order through the same normalization path as local web inject (`ActionService.AddAction()`), writing to **local Redis** for BP_MQX_ETH consumption.

#### Scenario: Cloud order reaches local Redis queue
- **WHEN** the agent applies a cloud action locally
- **THEN** `essensys:global:actions` on the gateway contains the normalized action payload

### Requirement: Agent acknowledges completion to hub
After local enqueue succeeds, the agent SHALL call `POST https://mon.essensys.fr/api/gateway/actions/{guid}/done`.

#### Scenario: Done ack updates cloud status
- **WHEN** local apply succeeds
- **THEN** the cloud action status becomes `done` on the VPS

### Requirement: Agent sends heartbeat
The agent SHALL POST heartbeat to `https://mon.essensys.fr/api/gateway/heartbeat` at a configurable interval (default 60s) with gateway identity.

#### Scenario: Heartbeat updates last seen
- **WHEN** heartbeat succeeds
- **THEN** `gateway_sessions.last_seen` is updated and portal UI can show gateway online
