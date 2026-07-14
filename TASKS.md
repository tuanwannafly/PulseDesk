# PulseDesk — Task breakdown & hour estimates

> This file is the "estimate tasks" deliverable referenced by the JD.
> Estimates are best-case single-developer hours including code, tests, and review.

## Sprint 0 — Setup & Multi-tenant foundation (12 h)

| # | Task | Hours | Branch |
|---|---|---|---|
| 0.1 | `rails new pulsedesk -d postgresql --css=tailwind` + Gemfile (sidekiq, rspec, factory_bot, faker, rubocop, dotenv-rails) | 1.5 | `feature/s0-project-setup` |
| 0.2 | Configure database.yml, sidekiq config, redis initializer, credentials | 1.0 | `feature/s0-project-setup` |
| 0.3 | Draw ERD, write migration for `accounts` + `users` | 1.0 | `feature/s1-tenant-scoping` |
| 0.4 | `Current` (ActiveSupport::CurrentAttributes) and `TenantScoped` concern | 1.5 | `feature/s1-tenant-scoping` |
| 0.5 | `ApplicationController` set `Current.account` from `current_user.account` | 1.0 | `feature/s1-tenant-scoping` |
| 0.6 | Tenant isolation spec (Account A cannot read Account B) | 2.0 | `feature/s1-tenant-scoping` |
| 0.7 | `User` + `Account` model specs, devise-or-`has_secure_password` auth, sessions controller | 2.0 | `feature/s1-tenant-scoping` |
| 0.8 | Base Tailwind layout + simple login form | 2.0 | `feature/s1-tenant-scoping` |

**Sprint 0 total: 12 h** → tag `v0.1`

## Sprint 1 — Ticket core & conversation thread (10 h)

| # | Task | Hours | Branch |
|---|---|---|---|
| 1.1 | Migrations: `customers`, `tickets`, `ticket_messages`, `tags`, `ticket_tags` | 1.5 | `feature/s2-tickets` |
| 1.2 | Models w/ `TenantScoped`; `Ticket` enums (status, priority); associations | 1.5 | `feature/s2-tickets` |
| 1.3 | Composite indexes `(account_id, status)`, `(account_id, created_at)` | 0.5 | `feature/s2-tickets` |
| 1.4 | `TicketsController` (CRUD, scoped) + form helpers | 2.0 | `feature/s2-tickets` |
| 1.5 | Inbox-style index view (Tailwind, responsive) | 1.5 | `feature/s2-tickets` |
| 1.6 | `TicketMessagesController`, thread view, message form | 2.0 | `feature/s3-ticket-messages` |
| 1.7 | Tag CRUD + checkboxes in ticket form (has_many :through) | 1.0 | `feature/s3-ticket-messages` |

**Sprint 1 total: 10 h** → tag `v0.2`

## Sprint 2 — AI classification via background job (8 h)

| # | Task | Hours | Branch |
|---|---|---|---|
| 2.1 | Add `ai_summary`, `sentiment_score`, `ai_suggested_priority` columns | 0.5 | `feature/s4-ai-classification` |
| 2.2 | `TicketClassifierService` (PORO) w/ HTTP client + JSON parse + retries | 2.0 | `feature/s4-ai-classification` |
| 2.3 | `TicketClassificationJob` + Sidekiq adapter + `after_create_commit` enqueue | 1.5 | `feature/s4-ai-classification` |
| 2.4 | Graceful fallback on timeout / 5xx / JSON parse failure | 1.0 | `feature/s4-ai-classification` |
| 2.5 | RSpec: mock LLM response, verify job enqueue, verify fallback | 2.0 | `feature/s4-ai-classification` |
| 2.6 | UI: sentiment badge + AI summary on ticket list / detail | 1.0 | `feature/s4-ai-classification` |

**Sprint 2 total: 8 h** → tag `v0.3`

## Sprint 3 — Analytics dashboard + assignment locking (10 h)

| # | Task | Hours | Branch |
|---|---|---|---|
| 3.1 | `AnalyticsQuery` class — query 1: avg response time per agent (raw SQL, JOIN) | 1.5 | `feature/s5-analytics` |
| 3.2 | Query 2: sentiment trend by week (window function) | 1.5 | `feature/s5-analytics` |
| 3.3 | Query 3: top tags by account (GROUP BY + COUNT) | 1.0 | `feature/s5-analytics` |
| 3.4 | Dashboard view + Chartkick wiring | 1.5 | `feature/s5-analytics` |
| 3.5 | `AssignmentService` w/ `Ticket.lock.find` pessimistic locking | 1.5 | `feature/s6-assignment-locking` |
| 3.6 | `EscalationPolicy` PORO (auto-upgrade priority after X hours) | 1.0 | `feature/s6-assignment-locking` |
| 3.7 | Concurrency spec: 2 threads claim same ticket → only one wins | 2.0 | `feature/s6-assignment-locking` |

**Sprint 3 total: 10 h** → tag `v0.4`

## Sprint 4 — Testing, polish, deploy (6 h)

| # | Task | Hours | Branch |
|---|---|---|---|
| 4.1 | Multi-tenant seed (`db/seeds.rb` — 3 demo tenants, customers, tickets, messages, tags) | 1.5 | `feature/s7-testing` |
| 4.2 | Request specs: full lifecycle create → classify → assign → resolve | 2.0 | `feature/s7-testing` |
| 4.3 | CSS polish (responsive inbox + dashboard) | 1.0 | `feature/s7-testing` |
| 4.4 | `README.md` complete, `.github/workflows/ci.yml` (RSpec + Rubocop) | 1.0 | `feature/s7-testing` |
| 4.5 | Smoke test + tag `v1.0` | 0.5 | `release/v1.0` |

**Sprint 4 total: 6 h** → tag `v1.0`

## Grand total: 46 h ≈ 6 working days

Sprint 0 + 1 are mandatory (tenant scoping is the architectural backbone).
Sprint 2 (AI classification) is the unique differentiator vs other intern candidates
and should not be cut. Sprint 3 / 4 can be trimmed if deadline is tight (e.g.,
reduce analytics from 3 reports → 1, drop escalation policy).