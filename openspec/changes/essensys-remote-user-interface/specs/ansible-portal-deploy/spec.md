## ADDED Requirements

### Requirement: support-site.yml includes portal roles
The Ansible playbook `essensys-ansible/support-site.yml` SHALL include roles `portal_backend`, `portal_frontend`, and `portal_nginx` after existing `backend` and `frontend` roles.

#### Scenario: Playbook lists portal roles
- **WHEN** `support-site.yml` is read
- **THEN** it references `portal_backend`, `portal_frontend`, and `portal_nginx` in order

### Requirement: Portal backend deployed on port 8081
Role `portal_backend` SHALL clone `essensys-user-portal-backend`, build the Go binary, install a systemd unit, and listen on **`127.0.0.1:8081`** (configurable via `portal_backend_port`).

#### Scenario: Systemd service active
- **WHEN** playbook completes on OVH
- **THEN** `systemctl is-active essensys-portal-backend` returns `active` and port 8081 listens locally

### Requirement: Nginx routes portal and gateway APIs
Role `portal_nginx` SHALL configure Nginx to proxy `/api/portal/` and `/api/gateway/` to portal-backend and serve `/portal/` from deployed frontend static files.

#### Scenario: Portal static path works
- **WHEN** `curl -sS -o /dev/null -w '%{http_code}\n' https://mon.essensys.fr/portal/`
- **THEN** the response code is 200 after deployment

#### Scenario: Portal API proxied
- **WHEN** `curl -sS https://mon.essensys.fr/api/portal/health` is called
- **THEN** the request reaches portal-backend via Nginx

### Requirement: Ansible variables documented
Group variables SHALL document `portal_backend_repo`, `portal_frontend_repo`, `portal_backend_port`, and `cloud_hub_public_url` defaulting to `https://mon.essensys.fr`.

#### Scenario: Variables in group_vars or role defaults
- **WHEN** operator inspects portal role defaults
- **THEN** repository URLs and port variables are defined with essensys-hub GitHub URLs
