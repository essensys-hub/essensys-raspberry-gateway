## ADDED Requirements

### Requirement: Support-site backend marked deprecated
After production cutover, `essensys-support-site/backend/` SHALL be marked deprecated in README with pointer to `essensys-user-portal-backend`.

#### Scenario: README deprecation notice
- **WHEN** a developer opens `essensys-support-site/README.md` after cutover
- **THEN** it states that backend logic moved to consolidated cloud backend and `backend/` will be removed

### Requirement: Git archive tag before removal
A git tag (e.g. `support-backend-last`) SHALL be created on the last commit containing `essensys-support-site/backend/` before directory deletion.

#### Scenario: Tag exists for rollback reference
- **WHEN** backend directory is removed from support-site repo
- **THEN** tag `support-backend-last` points to recoverable backend source

### Requirement: Ansible backend role removed or redirected
The Ansible `roles/backend` role that builds `essensys-support-site/backend` SHALL be removed or redirect to consolidated `cloud_backend` role when `cloud_backend_consolidated: true`.

#### Scenario: Playbook no longer clones support-site for Go binary
- **WHEN** consolidated deploy is active
- **THEN** `support-site.yml` does not build a separate Go binary from `essensys-support-site/backend`

### Requirement: Support-site repo retains frontend only
The `essensys-support-site` repository SHALL continue to deploy the React SPA (`site/`) and Nginx config; only the Go backend subdirectory is removed.

#### Scenario: Frontend deploy unchanged
- **WHEN** Ansible runs frontend role after backend removal
- **THEN** `https://mon.essensys.fr/` serves the support-site SPA as before
