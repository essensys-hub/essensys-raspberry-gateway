## ADDED Requirements

### Requirement: Legacy IoT routes with stable paths
The consolidated backend SHALL expose passive IoT routes at unchanged paths: `POST /api/mystatus`, `GET /api/myactions`, `GET /api/serverinfos`, `POST /api/infos`.

#### Scenario: MyStatus with valid Basic Auth
- **WHEN** a legacy machine posts telemetry to `POST /api/mystatus` with valid Basic Auth credentials
- **THEN** the server stores telemetry and returns HTTP 200

#### Scenario: MyActions returns empty object
- **WHEN** a legacy machine requests `GET /api/myactions` with valid Basic Auth
- **THEN** the response body is `{}` (passive mode — no cloud orders via this path)

#### Scenario: ServerInfos returns index list
- **WHEN** a machine requests `GET /api/serverinfos`
- **THEN** the response includes the configured index collection list and `isconnected: false`

### Requirement: Basic Auth legacy compatibility
Basic Auth SHALL decode `username:password` into `hashed_pkey`, auto-register unknown machines, and enforce strict mode on mystatus/myactions.

#### Scenario: Unknown machine auto-registered
- **WHEN** a new machine authenticates with Basic Auth for the first time
- **THEN** a machine record is created with client ID derived from credentials

### Requirement: Gateway push status via infos
`POST /api/infos` SHALL accept gateway system status JSON from CM5 `push_status.py` and store it for admin gateway monitoring.

#### Scenario: Gateway infos heartbeat stored
- **WHEN** a gateway posts system metrics to `POST /api/infos`
- **THEN** admin `GET /api/admin/gateways` reflects updated status
