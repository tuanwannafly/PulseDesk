# Changelog

All notable changes to **PulseDesk** are documented here.
This project follows [Semantic Versioning](https://semver.org/).

## [Unreleased] — Sprint 4 finalization
### Added
- Request specs covering full ticket lifecycle and cross-tenant safety
- `AnalyticsQuery` raw-SQL reports (avg response time, sentiment trend, top tags)
- `AssignmentService` with `SELECT … FOR UPDATE` pessimistic locking
- `EscalationPolicy` PORO for auto-priority upgrade
- `db/seeds.rb` seeds 3 demo tenants for live demo
- `.github/workflows/ci.yml` — RSpec + RuboCop on every push
- Procfile for Render / Fly.io deployment
- `docs/DEPLOYMENT.md`

## [v0.4] — Sprint 3 (Analytics + Concurrency)
### Added
- `analytics_dashboard` route + Chartkick views
- Concurrency spec proving pessimistic locking works under contention

## [v0.3] — Sprint 2 (AI Classification)
### Added
- `TicketClassifierService` calling OpenRouter / Groq with retry + JSON parse
- `TicketClassificationJob` (ActiveJob + Sidekiq)
- Graceful fallback (`"AI unavailable (…)"`) when the provider is down
- Sentiment badge on ticket list + detail

## [v0.2] — Sprint 1 (Ticket Core)
### Added
- `Customer`, `Ticket`, `TicketMessage`, `Tag`, `TicketTag` models
- Inbox-style ticket UI (Tailwind)
- Conversation thread view

## [v0.1] — Sprint 0 (Foundation)
### Added
- Rails 7.1 app with PostgreSQL, Tailwind, Sidekiq
- `TenantScoped` concern + `Current.account` (ActiveSupport::CurrentAttributes)
- `Account` + `User` models with `has_secure_password`
- `SessionsController`, `UsersController`
- Tenant isolation spec (the cornerstone test of the project)

[Unreleased]: https://github.com/<owner>/pulsedesk/compare/v0.4...HEAD
[v0.4]: https://github.com/<owner>/pulsedesk/compare/v0.3...v0.4
[v0.3]: https://github.com/<owner>/pulsedesk/compare/v0.2...v0.3
[v0.2]: https://github.com/<owner>/pulsedesk/compare/v0.1...v0.2
[v0.1]: https://github.com/<owner>/pulsedesk/releases/tag/v0.1