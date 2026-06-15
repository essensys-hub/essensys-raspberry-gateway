## ADDED Requirements

### Requirement: WAN HTTPS validation script exists
The repository SHALL provide `scripts/test-wan-https-ovh.sh` (or equivalent Ansible role) executable on a CM5 gateway to validate outbound connectivity to `https://mon.essensys.fr`.

#### Scenario: Script exits success on healthy gateway
- **WHEN** the script runs on a gateway with working eth0 Internet and valid DNS
- **THEN** exit code is 0 and output confirms HTTPS 200/301 to `https://mon.essensys.fr`

### Requirement: Script verifies no HTTP hub usage
The validation script SHALL fail or warn if plain `http://mon.essensys.fr` is used as the configured hub URL in gateway config.

#### Scenario: HTTP hub URL flagged
- **WHEN** gateway config contains `hub_url: http://mon.essensys.fr`
- **THEN** the validation script reports failure and instructs to use HTTPS

### Requirement: Eth0 default route to Internet
The script SHALL verify that routes to the OVH public IP for `mon.essensys.fr` egress via **eth0**, not eth1.

#### Scenario: Route uses eth0
- **WHEN** `ip route get <ovh_ip>` is evaluated on a dual-NIC gateway
- **THEN** the output interface is eth0

### Requirement: Prerequisite documented in install guide
`essensys-ansible/docs/install-gateway.md` SHALL include a **Connectivité cloud** section referencing the script and checklist before enabling portal features.

#### Scenario: Documentation references script
- **WHEN** an operator reads install-gateway cloud section
- **THEN** they find the script path and expected pass criteria
