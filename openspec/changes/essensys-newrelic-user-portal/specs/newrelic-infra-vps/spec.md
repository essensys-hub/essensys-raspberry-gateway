## ADDED Requirements

### Requirement: Infrastructure agent installs conditionally via Ansible
The Ansible role `newrelic_infra` SHALL install and configure the New Relic Infrastructure agent on the OVH VPS only when `newrelic_enabled` is `true`.

#### Scenario: Agent installed when enabled
- **WHEN** `ansible-playbook support-site.yml` runs with `newrelic_enabled: true` and a valid vault license key
- **THEN** `newrelic-infra` service is enabled and active on the target host

#### Scenario: Agent skipped when disabled
- **WHEN** `ansible-playbook support-site.yml` runs with `newrelic_enabled: false`
- **THEN** the playbook completes without requiring New Relic APT packages or a license key

### Requirement: License key is supplied from Ansible Vault
The infrastructure agent configuration SHALL read the New Relic license key from `vault_newrelic_license_key` (or equivalent vault variable) and SHALL NOT store the key in plain-text group_vars committed to git.

#### Scenario: Config file uses vaulted key at deploy time
- **WHEN** the role templates `/etc/newrelic-infra.yml`
- **THEN** the license key value comes from an Ansible Vault variable

### Requirement: Host display name identifies OVH VPS
The infrastructure agent SHALL use display name `ovh-mon-essensys` (configurable via `newrelic_infra_display_name`) so the host is identifiable in New Relic.

#### Scenario: Host appears with expected name
- **WHEN** the agent reports metrics after deployment
- **THEN** the entity display name matches `newrelic_infra_display_name` defaulting to `ovh-mon-essensys`

### Requirement: Optional integrations for Nginx and PostgreSQL
When `newrelic_infra_integrations.nginx` or `newrelic_infra_integrations.postgresql` are true, the role SHALL enable the corresponding New Relic on-host integrations.

#### Scenario: Nginx integration enabled
- **WHEN** `newrelic_infra_integrations.nginx` is true
- **THEN** Nginx metrics are collected by the infrastructure agent integrations

#### Scenario: PostgreSQL integration enabled
- **WHEN** `newrelic_infra_integrations.postgresql` is true
- **THEN** PostgreSQL metrics are collected for the local Essensys database instance
