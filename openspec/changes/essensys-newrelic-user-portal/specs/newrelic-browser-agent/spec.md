## ADDED Requirements

### Requirement: Browser agent initializes only when enabled at build time
The frontend SHALL load the New Relic browser agent only when `VITE_NEW_RELIC_ENABLED` equals `true` at build time. When disabled, the application SHALL behave identically to the pre-instrumentation build.

#### Scenario: Local dev build without New Relic
- **WHEN** `npm run build` runs without `VITE_NEW_RELIC_ENABLED=true`
- **THEN** the production bundle contains no active New Relic network calls on page load

#### Scenario: Production build with New Relic enabled
- **WHEN** `npm run build` runs with `VITE_NEW_RELIC_ENABLED=true` and valid `VITE_NEW_RELIC_*` identifiers
- **THEN** the browser agent initializes once at application boot

### Requirement: SPA page views are recorded on route changes
The frontend SHALL report page views when the user navigates between routes under `/portal/*` using React Router.

#### Scenario: Dashboard navigation sends page view
- **WHEN** New Relic Browser is enabled and the user navigates to `/portal/dashboard`
- **THEN** a page view action is sent to New Relic Browser

### Requirement: API errors are reported without auth secrets
The portal API client SHALL call New Relic `noticeError` (or equivalent) on HTTP 5xx and network failures without including JWT or `Authorization` header values in error attributes.

#### Scenario: 500 response triggers browser error notice
- **WHEN** New Relic Browser is enabled and a portal API call returns HTTP 500
- **THEN** an error notice is sent to New Relic without the request Authorization value

### Requirement: Build-time variables are documented
The frontend README SHALL document all `VITE_NEW_RELIC_*` variables required for production builds.

#### Scenario: Developer finds browser env documentation
- **WHEN** a developer reads the frontend README
- **THEN** Vite New Relic variables and the production-only enablement policy are listed
