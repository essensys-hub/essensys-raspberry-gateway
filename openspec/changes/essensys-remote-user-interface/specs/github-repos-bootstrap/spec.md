## ADDED Requirements

### Requirement: GitHub repos created under essensys-hub
Two public repositories SHALL exist under [essensys-hub](https://github.com/orgs/essensys-hub/repositories):
- `essensys-user-portal-backend`
- `essensys-user-portal-frontend`

Each SHALL use MIT license and follow naming conventions of existing Essensys repos.

#### Scenario: Backend repo exists
- **WHEN** an operator runs `gh repo view essensys-hub/essensys-user-portal-backend`
- **THEN** the repository is accessible with README and initial project scaffold

#### Scenario: Frontend repo exists
- **WHEN** an operator runs `gh repo view essensys-hub/essensys-user-portal-frontend`
- **THEN** the repository is accessible with README and Vite React scaffold

### Requirement: CI workflows on both repos
Each new repository SHALL include GitHub Actions for build verification (`go test ./...` for backend, `npm run lint && npm run build` for frontend).

#### Scenario: Backend CI passes on main
- **WHEN** code is pushed to default branch
- **THEN** the backend workflow completes successfully on scaffold commit

### Requirement: Backend project structure follows domain layout
The backend repo SHALL use `cmd/server`, `internal/domain`, `internal/api`, `internal/data` packages. Generic package names `utils`, `helpers`, or `common` SHALL NOT be used for domain logic.

#### Scenario: Layout matches convention
- **WHEN** the repository tree is inspected
- **THEN** `cmd/server/main.go` and `internal/api` exist without a root-level `utils` dump package
