# PulseDesk

> AI-Powered Multi-Tenant Customer Support & Feedback Analytics SaaS
> Built with Ruby on Rails 7.1 — showcasing multi-tenant architecture, AI integration, advanced SQL, and concurrency control in a single demoable product.

PulseDesk is a small-but-complete SaaS that lets small businesses manage customer support tickets across multiple tenants, with automatic AI classification (summary, sentiment, suggested priority) running async via background jobs, an analytics dashboard powered by raw SQL, and pessimistic-locking ticket assignment to handle concurrent "Claim" requests safely.

Three demo tenants ship out of the box so you can open two browsers, sign into different tenants, and **see** the tenant-isolation story with your own eyes.

---

## Table of contents

- [1. Features at a glance](#1-features-at-a-glance)
- [2. Quick start (local, 5 minutes)](#2-quick-start-local-5-minutes)
- [3. Demo accounts](#3-demo-accounts)
- [4. Architecture](#4-architecture)
- [5. Domain model (ERD)](#5-domain-model-erd)
- [6. Multi-tenancy — the centerpiece](#6-multi-tenancy--the-centerpiece)
- [7. AI classification pipeline](#7-ai-classification-pipeline)
- [8. Concurrency — pessimistic locking](#8-concurrency--pessimistic-locking)
- [9. Analytics — raw SQL reports](#9-analytics--raw-sql-reports)
- [10. Background jobs](#10-background-jobs)
- [11. Testing](#11-testing)
- [12. Code quality (Rubocop)](#12-code-quality-rubocop)
- [13. Project layout](#13-project-layout)
- [14. Deployment (Render / Fly.io)](#14-deployment-render--flyio)
- [15. Mapping to a typical Ruby/Rails JD](#15-mapping-to-a-typical-rubyrails-jd)
- [16. Sprint plan & estimation](#16-sprint-plan--estimation)
- [17. Talking points for interviews](#17-talking-points-for-interviews)
- [18. Troubleshooting](#18-troubleshooting)

---

## 1. Features at a glance

| Feature | Where it lives | Why it matters |
|---|---|---|
| **Multi-tenant isolation** | `app/models/concerns/tenant_scoped.rb`, `app/models/current.rb` | Data leakage between tenants is the #1 SaaS bug. We prevent it by construction, not by convention. |
| **Tenant-scoped authentication** | `app/controllers/sessions_controller.rb`, `app/controllers/application_controller.rb` | Subdomain + email + password scoped per tenant |
| **Ticket lifecycle** (create / claim / reply / resolve) | `app/controllers/tickets_controller.rb`, `ticket_messages_controller.rb` | The bread-and-butter of a support desk |
| **AI auto-classification** (summary / sentiment / priority) | `app/services/ticket_classifier_service.rb`, `app/jobs/ticket_classification_job.rb` | Differentiator — async via background jobs with graceful fallback |
| **Concurrency-safe assignment** | `app/services/assignment_service.rb` | `SELECT … FOR UPDATE` so two agents can't claim the same ticket |
| **Auto-escalation policy** | `app/services/escalation_policy.rb` | Pure PORO — business rule lives outside ActiveRecord callbacks |
| **Analytics dashboard** (avg response time / sentiment trend / top tags) | `app/services/analytics_query.rb`, `app/controllers/dashboard_controller.rb` | Raw SQL with `JOIN`, `GROUP BY`, window functions, always tenant-scoped |
| **Tags (many-to-many)** | `app/models/tag.rb`, `ticket_tag.rb` | `has_many :through` with composite unique index |
| **Tests** | `spec/` (62 specs) | Model + service + job + request specs; WebMock for AI |
| **CI** | `.github/workflows/ci.yml` | RSpec + Rubocop on every push |
| **Production-ready deployment** | `render.yaml`, `Dockerfile`, `Procfile` | One-click deploy on Render with Redis add-on for Sidekiq |

---

## 2. Quick start (local, 5 minutes)

### Prerequisites

- **Ruby 4.0.5+** (developed on 4.0.5; Rails 7.1 works on 3.2+)
- **Bundler 2.x**
- **SQLite3** (default — no setup needed) **or PostgreSQL 14+** (production-grade)
- **Redis** *(only needed if you want to run Sidekiq instead of the in-process `:async` adapter)*
- **LLM API key** *(optional — the app gracefully falls back if the key is missing or the API is down)*

### 1. Clone & install dependencies

```bash
git clone <this-repo>
cd pulsedesk
bundle install
```

### 2. Configure environment

```bash
cp .env.example .env
# Edit .env — only LLM_* vars matter. Everything else has sensible defaults.
```

Minimum `.env` for local dev (SQLite, no Redis):

```ini
RAILS_ENV=development
SECRET_KEY_BASE=anything-secret-not-used-in-production

# Optional — leave LLM_API_KEY blank to test the graceful-fallback path
LLM_PROVIDER=openrouter
LLM_API_KEY=
LLM_MODEL=meta-llama/llama-3.1-8b-instruct:free
LLM_TIMEOUT=20
```

### 3. Create the database, run migrations, seed demo data

```bash
bin/rails db:create db:migrate db:seed
```

`db/seeds.rb` creates **3 demo tenants** (Acme / Globex / Initech) with users, customers, tags, and tickets — so you can demo tenant isolation immediately.

### 4. Run the server

```bash
bin/rails server
```

Open `http://localhost:3000` → you'll be redirected to `/login`.

### 5. Sign in

Pick any tenant from the [demo accounts](#3-demo-accounts) table below.

### 6. Run the tests (optional, but recommended)

```bash
bundle exec rspec        # 62 specs, ~3 seconds
bundle exec rubocop      # 72 files, 0 offenses
```

That's the whole loop. To stop the server: `Ctrl-C`.

---

## 3. Demo accounts

All demo users share the password `password123` (defined in `db/seeds.rb`).

| Subdomain | Email | Role | Plan |
|---|---|---|---|
| `acme` | `admin@acme.test` | admin | pro |
| `acme` | `agent@acme.test` | agent | pro |
| `globex` | `admin@globex.test` | admin | free |
| `initech` | `admin@initech.test` | admin | enterprise |
| `initech` | `iris@initech.test` | agent | enterprise |

> **Tenant isolation demo tip:** open two browser windows (or one incognito + one regular), sign into `acme` in window #1 and `globex` in window #2. Create a ticket in Acme — you won't see it in Globex's inbox, and direct URL access (`/tickets/<acme_ticket_id>`) returns **404 Not Found**.

---

## 4. Architecture

```
                ┌──────────────────────────────────────────────────┐
                │              Browser (per tenant)                │
                │      subdomain.acme.app   →  Acme's inbox        │
                │      subdomain.globex.app →  Globex's inbox      │
                └─────────────────────┬────────────────────────────┘
                                      │ HTTPS
                ┌─────────────────────▼────────────────────────────┐
                │        ApplicationController#set_current_attributes
                │        (authenticate, then Current.account = ...) │
                └─────────────────────┬────────────────────────────┘
                                      │
              ┌───────────────────────┼─────────────────────────┐
              │                       │                         │
   ┌──────────▼─────────┐  ┌──────────▼──────────┐  ┌──────────▼──────────┐
   │   Controllers      │  │   Models            │  │   Background jobs    │
   │  (Rails MVC)       │  │  (TenantScoped)     │  │  (ActiveJob)         │
   │                    │  │                     │  │                      │
   │  TicketsController │  │  Account            │  │  TicketClassification│
   │  CustomersCtrl     │  │  User  ↳ TenantScoped│  │  Job (async AI call) │
   │  TagsController    │  │  Customer↳Scoped    │  │                      │
   │  DashboardCtrl     │  │  Ticket ↳ Scoped    │  │  Adapter:            │
   │  SessionsCtrl      │  │  TicketMessage      │  │   dev  → :async      │
   │                    │  │  Tag ↳ Scoped       │  │   test → :test       │
   └─────────┬──────────┘  └─────────┬───────────┘  │   prod → :sidekiq   │
             │                       │              └──────────┬───────────┘
             │                       │                         │
             │             ┌─────────▼──────────┐   ┌──────────▼───────────┐
             │             │   Services          │   │   External           │
             │             │  (PORO/SOA)         │   │   dependencies      │
             │             │                     │   │                     │
             │             │  AnalyticsQuery    │   │  LLM API            │
             │             │   (raw SQL)         │   │   (OpenRouter/Groq) │
             │             │  AssignmentService  │   │                     │
             │             │   (pessimistic lock)│   │  Redis (prod only)  │
             │             │  EscalationPolicy   │   │   (Sidekiq broker)  │
             │             │  TicketClassifier   │   │                     │
             │             └─────────────────────┘   └─────────────────────┘
             │                       │
   ┌─────────▼───────────────────────▼──────────┐
   │              Database                      │
   │  (SQLite for dev / PostgreSQL for prod)    │
   │                                            │
   │  7 tables, all keyed by account_id         │
   │  Composite indexes for tenant-scoped queries│
   └────────────────────────────────────────────┘
```

The whole application has **three trust boundaries**:

1. **HTTP request → ApplicationController** — sets `Current.account` from the authenticated session
2. **Application code → TenantScoped records** — every `SELECT` is implicitly scoped
3. **Background jobs → TenantScoped records** — `Current.account` is set explicitly inside the job before touching data

---

## 5. Domain model (ERD)

```
                        ┌──────────────┐
                        │   accounts   │  ← tenant
                        │──────────────│
                        │ id           │
                        │ company_name │
                        │ subdomain  UK│
                        │ plan         │
                        └──────┬───────┘
                               │ 1
            ┌──────────────────┼──────────────────┬────────────────────┐
            │ N                │ N                │ N                  │ N
   ┌────────▼────────┐ ┌───────▼──────┐  ┌────────▼────────┐  ┌───────▼──────┐
   │     users       │ │  customers   │  │     tickets     │  │     tags     │
   │─────────────────│ │──────────────│  │─────────────────│  │──────────────│
   │ account_id  FK  │ │ account_id FK│  │ account_id   FK │  │ account_id FK│
   │ email        UK │ │ name         │  │ customer_id  FK │  │ name      UK │
   │ role            │ │ email        │  │ assigned_to FK  │  │ color        │
   │ password_digest │ │ notes        │  │ subject         │  └──────┬───────┘
   └─────────────────┘ └──────────────┘  │ status enum      │         │ M
                                  1   │ priority enum    │         │
                                  │   │ ai_summary       │         │
                                  │   │ sentiment_score  │         │
                                  │   │ ai_sugg_priority │         │
                                  │   │ first_response_at│         │
                                  │   │ resolved_at      │         │
                                  │   │ escalated_at     │         │
                                  │   └────────┬─────────┘         │
                                  │            │ 1                 │
                                  │            │                   │
                                  │   ┌────────▼──────────┐   ┌────▼─────────┐
                                  │   │ ticket_messages   │   │  ticket_tags │  ← join table
                                  │   │───────────────────│   │──────────────│
                                  └───│ ticket_id      FK │   │ ticket_id FK │
                                      │ user_id       FK? │   │ tag_id    FK │
                                      │ customer_id   FK? │   │ UK(ticket,tag)│
                                      │ sender_type       │   └──────────────┘
                                      │ body              │
                                      └───────────────────┘
```

### Composite indexes — designed for tenant-scoped queries

Every tenant-scoped FK comes paired with an index on `(account_id, ...)` so the query planner can skip unrelated tenants at the index level:

```ruby
add_index :tickets,    [:account_id, :status],              # dashboard count by status
add_index :tickets,    [:account_id, :priority],            # escalation policy
add_index :tickets,    [:account_id, :created_at],          # inbox sort
add_index :tickets,    [:account_id, :assigned_to_id],      # "my tickets" view
add_index :tickets,    [:account_id, :sentiment_score]      # sentiment trend
add_index :tickets,    [:account_id, :escalated_at]         # SLA breach queries
add_index :ticket_messages, [:account_id, :ticket_id, :created_at]   # conversation thread
add_index :users,      [:account_id, :email],     unique: true
add_index :tags,       [:account_id, :name],      unique: true
```

---

## 6. Multi-tenancy — the centerpiece

### The problem

In a multi-tenant SaaS, **a single line of forgotten `.where(account_id:)` is a CVE**. The solution is to make that mistake impossible at the language level.

### The mechanism: `default_scope` + `CurrentAttributes`

```ruby
# app/models/concerns/tenant_scoped.rb
module TenantScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :account, optional: true   # validations enforce presence instead
    default_scope { where(account_id: Current.account_id) }

    validates :account_id, presence: true, on: [:create, :update]
    before_validation :assign_default_account

    define_method(:assign_default_account) do
      self.account_id ||= Current.account_id
    end

    scope :for_account, ->(account) { unscoped.where(account_id: account.id) }
  end
end
```

```ruby
# app/models/current.rb
class Current < ActiveSupport::CurrentAttributes
  attribute :account, :user
end
```

```ruby
# app/controllers/application_controller.rb
before_action :set_current_attributes

def set_current_attributes
  Current.account = current_user&.account
end
```

### The proof — 3 guarantees, each backed by a spec

| Guarantee | What it means | The spec that proves it |
|---|---|---|
| **Tenant A cannot see Tenant B's rows** | `Customer.find(other_tenant_customer_id)` returns `nil` | `spec/models/concerns/tenant_scoped_spec.rb` |
| **Default scope never returns rows when `Current.account` is nil** | `Customer.all.to_a` returns `[]` in a background job that forgot to set `Current.account` | `spec/models/concerns/tenant_scoped_spec.rb` |
| **Direct URL access across tenants is 404** | `GET /tickets/<other_tenant_ticket_id>` returns `404 Not Found` | `spec/requests/ticket_lifecycle_spec.rb` |

### The escape hatch

Sometimes you genuinely need to escape the scope — admin tools, console scripts, background jobs that span tenants. We provide a single, explicit scope that requires you to know which tenant you want:

```ruby
Customer.for_account(other_tenant)        # works
Customer.unscoped                         # discouraged; needs a code comment
```

---

## 7. AI classification pipeline

### Why async?

Calling an LLM API synchronously inside a Rails request means a slow API blocks the user (and a dead API takes down the support desk). The right pattern is **fire-and-forget into a background queue**.

### The flow

```
Browser POSTs /tickets
        │
        ▼
TicketsController#create
        │
        ├── Persists Ticket + initial TicketMessage (DB writes)
        │
        └── TicketClassificationJob.perform_later(@ticket.id)     ← enqueue, return 302
                │
                ▼ (background thread / Sidekiq worker)
TicketClassificationJob#perform
        │
        ├── Current.account = ticket.account     ← restore tenant context
        │
        └── TicketClassifierService.new(ticket).call
                │
                ├── Faraday POST → OpenRouter / Groq
                ├── Retries (Faraday middleware, 2 attempts with backoff)
                │
                └── Parse JSON → update!(ai_summary, sentiment_score, ai_suggested_priority)
```

### Graceful fallback — the production-grade part

A real LLM API is down ~1% of the time. A good SaaS doesn't 500 its customers because an upstream vendor hiccupped.

```ruby
# app/services/ticket_classifier_service.rb
def call
  return fallback('AI skipped (empty conversation)') if @ticket.messages_text.strip.empty?

  response = http_client.post(chat_endpoint, request_body)
  raise LLMUnavailableError, "HTTP #{response.status}" unless response.success?

  parse_response(response.body)
rescue Faraday::TimeoutError, Faraday::ConnectionFailed, JSON::ParserError,
       LLMUnavailableError => e
  Rails.logger.warn("[TicketClassifierService] #{e.class}: #{e.message}")
  fallback(e.message)
end

def fallback(reason)
  {
    summary:     "AI unavailable (#{reason})",
    sentiment:   0.0,
    priority:    @ticket.priority || 'normal'
  }
end
```

The job also uses Sidekiq's exponential-backoff retry, so a transient blip doesn't drop the classification — it just delays it.

### Configuring the LLM

```ini
# .env
LLM_PROVIDER=openrouter       # or 'groq'
LLM_API_KEY=sk-or-v1-...      # your OpenRouter key
LLM_MODEL=meta-llama/llama-3.1-8b-instruct:free
LLM_TIMEOUT=20                # seconds
```

Free models available on OpenRouter (no credit card required):

- `meta-llama/llama-3.1-8b-instruct:free`
- `google/gemma-2-9b-it:free`
- `mistralai/mistral-7b-instruct:free`

Leave `LLM_API_KEY` blank and you'll see fallback messages appear on tickets — the app stays fully usable.

### Testing strategy

```ruby
# spec/services/ticket_classifier_service_spec.rb
it 'parses a valid LLM JSON response and returns expected keys' do
  stub_request(:post, /openrouter\.ai/)
    .to_return(status: 200, body: { choices: [...] }.to_json)

  result = described_class.new(ticket).call
  expect(result[:summary]).to eq('Refund request')
end

it 'falls back gracefully on a 5xx response' do
  stub_request(:post, /openrouter\.ai/).to_return(status: 503)
  expect(described_class.new(ticket).call[:summary]).to include('AI unavailable')
end

it 'falls back gracefully on timeout' do
  stub_request(:post, /openrouter\.ai/).to_timeout
  expect(described_class.new(ticket).call[:summary]).to include('AI unavailable')
end
```

We never hit a real LLM API in tests — WebMock stubs every external call.

---

## 8. Concurrency — pessimistic locking

### The problem

Two agents click "Claim this ticket" at the same instant. Without locking, both reads see `assigned_to_id: nil`, both write `assigned_to_id: <self>`, and you have an audit-trail nightmare.

### The fix

```ruby
# app/services/assignment_service.rb
def call
  Ticket.transaction do
    locked = Ticket.lock.find(@ticket.id)   # SELECT … FOR UPDATE

    if locked.assigned_to_id.present? && locked.assigned_to_id != @user.id
      return Result.new(success?: false,
                        error: "Ticket already assigned to #{locked.assigned_to&.name}",
                        ticket: locked)
    end

    locked.update!(assigned_to_id: @user.id,
                   status: locked.status == 'open' ? 'pending' : locked.status)
    EscalationPolicy.reset_for(locked)
    Result.new(success?: true, error: nil, ticket: locked)
  end
end
```

The second concurrent caller **blocks** on the database row lock until the first transaction commits, then re-reads with the new `assigned_to_id` and gets the friendly error.

### Why pessimistic, not optimistic?

- **Optimistic locking** (`lock_version`) is great when conflicts are rare — the second writer retries with fresh data.
- **Pessimistic locking** (`SELECT … FOR UPDATE`) is great when the conflict window is short and you want a hard guarantee that one and only one writer wins.

For ticket claim, pessimistic is the right call: the transaction takes milliseconds, the user expects instant feedback, and "you lost the race, please refresh" is a fine UX.

### Test strategy

```ruby
# spec/services/assignment_service_spec.rb
it 'serializes concurrent claims on the same ticket' do
  results = 5.times.map { Thread.new { AssignmentService.new(ticket, users.sample).call } }
                 .map(&:value)

  successes = results.select(&:success?)
  expect(successes.size).to eq(1)
  expect(successes.first.ticket.reload.assigned_to_id).not_to be_nil
end
```

The concurrency spec is tagged `:concurrency` and excluded from the default run on Windows (where SQLite is single-writer and the test would just hang). Run it on Postgres:

```bash
RUN_CONCURRENCY_SPECS=1 bundle exec rspec --tag concurrency
```

---

## 9. Analytics — raw SQL reports

Every analytic query lives in **one** class (`AnalyticsQuery`), takes `account_id` as a **required** first positional argument, and binds it via parameterized SQL — never string interpolation. The class can't be misused.

### Report 1 — Average response time per agent

```sql
SELECT
  u.id                                AS user_id,
  u.name                              AS agent_name,
  AVG(EXTRACT(EPOCH FROM (first_reply.first_reply_at - t.created_at)) / 3600.0)
                                       AS avg_response_hours,
  COUNT(t.id)                         AS tickets_handled
FROM users u
LEFT JOIN tickets t
  ON t.assigned_to_id = u.id
 AND t.account_id     = :account_id
 AND t.first_response_at IS NOT NULL
LEFT JOIN LATERAL (
  SELECT MIN(tm.created_at) AS first_reply_at
  FROM ticket_messages tm
  WHERE tm.ticket_id    = t.id
    AND tm.account_id   = :account_id
    AND tm.sender_type  = 'agent'
) AS first_reply ON TRUE
WHERE u.account_id = :account_id
  AND u.role       = 'agent'
GROUP BY u.id, u.name
HAVING COUNT(t.id) > 0
ORDER BY avg_response_hours ASC NULLS LAST;
```

### Report 2 — Sentiment trend by week (window function)

```sql
WITH weekly AS (
  SELECT
    date_trunc('week', t.created_at)::date AS week,
    AVG(t.sentiment_score)                 AS avg_sentiment,
    COUNT(*)                               AS ticket_count
  FROM tickets t
  WHERE t.account_id      = :account_id
    AND t.sentiment_score IS NOT NULL
  GROUP BY 1
)
SELECT
  week,
  avg_sentiment,
  ticket_count,
  AVG(avg_sentiment) OVER (
    ORDER BY week
    ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
  ) AS moving_avg_4w
FROM weekly
ORDER BY week ASC;
```

### Report 3 — Top tags by usage

```sql
SELECT
  tg.id, tg.name, tg.color,
  COUNT(tt.ticket_id) AS usage_count
FROM tags tg
LEFT JOIN ticket_tags tt
  ON tt.tag_id    = tg.id
 AND tt.account_id = :account_id
WHERE tg.account_id = :account_id
GROUP BY tg.id, tg.name, tg.color
HAVING COUNT(tt.ticket_id) > 0
ORDER BY usage_count DESC
LIMIT :lim;
```

### SQLite fallback

The class auto-detects the adapter and swaps to a SQLite-friendly version (using `julianday()` instead of `EXTRACT(EPOCH …)`, and `strftime` instead of `date_trunc`). This lets you run analytics on the SQLite dev DB without setting up Postgres locally.

```ruby
def average_response_time_per_agent
  sql = postgres? ? avg_response_time_sql : avg_response_time_sql_sqlite
  # ...
end
```

---

## 10. Background jobs

| Environment | Adapter | Use case |
|---|---|---|
| `development` | `:async` | No Redis required; jobs run on an in-process thread pool |
| `test` | `:test` | Synchronous; `have_enqueued_jobs` + `perform_enqueued_jobs` work as expected |
| `production` | `:sidekiq` | Redis-backed; survives process restarts; horizontal scaling |

```ruby
# config/application.rb
config.active_job.queue_adapter = :async

# config/environments/production.rb
config.active_job.queue_adapter = :sidekiq
```

The `Sidekiq` initializer at `config/initializers/sidekiq.rb` is **commented out** in the SQLite dev environment to keep `bin/rails server` self-contained. Uncomment when you're ready to deploy with Redis.

---

## 11. Testing

```bash
bundle exec rspec                # 62 examples, ~3s
bundle exec rspec spec/models    # model specs only
bundle exec rspec spec/services  # service / PORO specs only
RUN_CONCURRENCY_SPECS=1 bundle exec rspec --tag concurrency
```

### Coverage map

```
spec/models/                          →  unit tests for AR validations + scopes
├── account_spec.rb                  →  subdomain uniqueness, plan enum, downcasing
├── user_spec.rb                     →  auth, role enum, scoped email uniqueness
├── customer_spec.rb                 →  scoped email uniqueness
├── ticket_spec.rb                   →  status/priority enums, sentiment_label helper
├── ticket_message_spec.rb           →  sender_type, must_have_sender, after_create_commit
├── tag_spec.rb                      →  scoped name uniqueness
└── concerns/tenant_scoped_spec.rb   →  cross-tenant safety, no-current-account safety

spec/services/                        →  PORO / service objects (no DB unless seeded)
├── assignment_service_spec.rb       →  pessimistic locking, success + failure paths
├── escalation_policy_spec.rb        →  threshold-by-priority, idempotency
├── analytics_query_spec.rb          →  tenant isolation, raw SQL parameter binding
└── ticket_classifier_service_spec.rb →  WebMock stubs: success / 503 / timeout / bad JSON / empty

spec/jobs/                            →  background job behavior
└── ticket_classification_job_spec.rb →  enqueue, perform updates ticket, fallback path

spec/requests/                        →  end-to-end HTTP specs
├── auth_spec.rb                     →  wrong password / wrong subdomain / cross-tenant
└── ticket_lifecycle_spec.rb         →  create → classify → claim → reply → resolve, plus cross-tenant 404
```

### Configuration

- **DatabaseCleaner** uses `:truncation` strategy (because `TenantScoped` doesn't play nicely with transactions)
- **WebMock** disables all external HTTP by default, with `allow_localhost: true` for system tests
- **FactoryBot** discovers factories under `spec/factories/` automatically via `g.fixture_replacement`

---

## 12. Code quality (Rubocop)

```bash
bundle exec rubocop          # check, no autocorrect
bundle exec rubocop -a       # autocorrect safe cops
```

- **72 Ruby files** scanned
- **0 offenses** on the clean run
- `.rubocop.yml` ships with sensible defaults (line length 130, method length 25, block length 25, ABC size 30)
- `rails_helper.rb` and `db/seeds.rb` are excluded from `Metrics/BlockLength` (they're naturally long)
- `sessions_controller#create` is excluded from `Metrics/AbcSize` (auth lookup is genuinely branchy)

---

## 13. Project layout

```
pulsedesk/
├── app/
│   ├── controllers/              ← HTTP entry points
│   │   ├── application_controller.rb        (set_current_attributes, login guards)
│   │   ├── sessions_controller.rb           (subdomain+email+password login)
│   │   ├── tickets_controller.rb           (CRUD + claim/resolve/reopen)
│   │   ├── ticket_messages_controller.rb   (reply in a thread)
│   │   ├── customers_controller.rb         (end-user of each tenant)
│   │   ├── tags_controller.rb              (categorization)
│   │   ├── users_controller.rb             (admin agent management)
│   │   └── dashboard_controller.rb         (3 analytics reports)
│   │
│   ├── models/
│   │   ├── concerns/
│   │   │   └── tenant_scoped.rb   ← THE centerpiece, 25 lines, 6 specs
│   │   ├── account.rb             ← tenant root
│   │   ├── user.rb                ← has_secure_password, role: admin/agent
│   │   ├── customer.rb            ← end-user of a tenant
│   │   ├── ticket.rb              ← status/priority enum, sentiment_label
│   │   ├── ticket_message.rb      ← conversation thread
│   │   ├── ticket_tag.rb          ← join table
│   │   ├── tag.rb                 ← has_many :through
│   │   ├── current.rb             ← ActiveSupport::CurrentAttributes
│   │   └── application_record.rb  ← base class
│   │
│   ├── services/                  ← PORO / SOA
│   │   ├── analytics_query.rb        ← raw SQL, tenant-scoped
│   │   ├── assignment_service.rb     ← pessimistic locking
│   │   ├── escalation_policy.rb      ← auto priority upgrade
│   │   └── ticket_classifier_service.rb  ← Faraday + LLM API
│   │
│   ├── jobs/
│   │   ├── application_job.rb
│   │   └── ticket_classification_job.rb  ← async AI classify
│   │
│   ├── mailers/application_mailer.rb
│   └── views/                   ← ERB templates, Tailwind CSS
│
├── config/
│   ├── application.rb             ← loaded frameworks only (no ActiveStorage, no ActionCable)
│   ├── database.yml               ← SQLite by default, swap to PostgreSQL for prod
│   ├── routes.rb                  ← /login, /tickets, /dashboard, /sidekiq (dev only)
│   ├── storage.yml                ← disk service for ActiveStorage if added later
│   ├── initializers/
│   │   ├── 02_eager_load_paths.rb ← adds app/services to autoload (Rails 7.1 freeze workaround)
│   │   ├── filter_parameter_logging.rb
│   │   ├── inflections.rb
│   │   ├── session_store.rb
│   │   └── sidekiq.rb             ← COMMENTED for SQLite dev; uncomment for prod
│   └── environments/development.rb | test.rb | production.rb
│
├── db/
│   ├── migrate/                   ← 7 migrations, 7 tables, all tenant-keyed
│   ├── schema.rb                  ← auto-generated from current DB state
│   └── seeds.rb                   ← 3 demo tenants (Acme/Globex/Initech)
│
├── spec/                          ← 62 RSpec examples (model/service/job/request)
├── docs/                          ← architecture / deployment / security notes
├── .github/workflows/ci.yml       ← RSpec + Rubocop on every push
├── Dockerfile, render.yaml, Procfile   ← one-click deploy to Render / Fly.io
├── .rubocop.yml
├── .env.example
└── README.md (this file)
```

---

## 14. Deployment (Render / Fly.io)

### Render (one-click Blueprint)

The repo ships `render.yaml` with a complete Blueprint definition:

- Web service running Puma
- Postgres database (`pulsedesk-db`)
- Redis instance (`pulsedesk-redis`)
- Sidekiq worker dyno
- LLM_API_KEY / SECRET_KEY_BASE pulled from Render env-vars

Click the "Deploy to Render" button → set `LLM_API_KEY` in the dashboard → wait 3 minutes → live.

### Manual Postgres swap (local)

```ruby
# Gemfile
gem 'pg', '~> 1.5'

# config/database.yml (snippet)
production:
  adapter: postgresql
  url: <%= ENV['DATABASE_URL'] %>
```

Then:

```bash
bundle install --without development test
RAILS_ENV=production bin/rails db:create db:migrate db:seed
```

### Docker

```bash
docker build -t pulsedesk .
docker run -p 3000:3000 \
  -e DATABASE_URL=postgres://... \
  -e REDIS_URL=redis://... \
  -e LLM_API_KEY=sk-or-v1-... \
  pulsedesk
```

---

## 15. Mapping to a typical Ruby/Rails JD

| JD requirement | Where in PulseDesk |
|---|---|
| **HTML, CSS** | `app/views/**` with Tailwind CSS, responsive inbox layout |
| **OOP / SOLID** | `TenantScoped` concern (Sprint 0), `TicketClassifierService` / `AssignmentService` / `EscalationPolicy` (Sprints 2-3) |
| **Database design** | 7-table schema with FK constraints + composite indexes for tenant-scoped queries |
| **SQL** | `AnalyticsQuery` class: 3 raw reports using `JOIN`, `GROUP BY`, `COUNT`, `EXTRACT`, `LATERAL`, `OVER … ROWS BETWEEN` |
| **Concurrency** | `AssignmentService` with `Ticket.lock.find` (`SELECT … FOR UPDATE`); concurrency spec with 5 threads |
| **Ruby on Rails ecosystem** | ActiveRecord, ActiveJob (`:async` / `:test` / `:sidekiq`), `ActiveSupport::CurrentAttributes`, `has_secure_password`, `belongs_to` validations |
| **Testing (RSpec)** | 62 examples covering model / service / job / request; WebMock stubs every external call |
| **Git workflow** | Git Flow with `feature/*` → `develop` → `release/*` → `master`; Conventional Commits; tags at every sprint boundary |
| **Task estimation** | `TASKS.md` with per-task hour estimates — proof of "estimate tasks" JD requirement |
| **Production mindset** | Graceful fallback, retries with backoff, secrets via env, CI on every push, one-click deploy |

---

## 16. Sprint plan & estimation

Full plan in [`PulseDesk-Sprint-Plan.md`](./PulseDesk-Sprint-Plan.md). Hour-by-hour breakdown in [`TASKS.md`](./TASKS.md).

| Sprint | Days | Branch | Tag | Major deliverable |
|---|---|---|---|---|
| **0 — Setup & Multi-Tenant Foundation** | 1-2 | `feature/s0-project-setup`, `feature/s1-tenant-scoping` | `v0.1` | `TenantScoped` concern + isolation specs |
| **1 — Ticket Core & Conversation Thread** | 3-4 | `feature/s2-tickets`, `feature/s3-ticket-messages` | `v0.2` | CRUD + chat-style thread + tags |
| **2 — AI Classification (differentiator)** | 5 | `feature/s4-ai-classification` | `v0.3` | Async LLM job with fallback |
| **3 — Analytics & Concurrency** | 6-7 | `feature/s5-analytics`, `feature/s6-assignment-locking` | `v0.4` | 3 raw-SQL reports + pessimistic lock |
| **4 — Testing, Polish, Deploy** | 8-9 | `feature/s7-testing`, `release/v1.0` | `v1.0` | Request specs + seed + README + CI + live deploy |

---

## 17. Talking points for interviews

When asked "tell me about a Rails project you built", use this structure:

1. **Business problem.** Small businesses need a $50+/month Zendesk alternative. Multi-tenant SaaS is the cheapest way to serve them.

2. **Hardest architectural decision.** Multi-tenant with shared database. The risk is data leakage between tenants — a single forgotten `.where(account_id: …)` is a CVE. I solved it at the language level: `TenantScoped` concern with `default_scope { where(account_id: Current.account_id) }` makes leakage impossible, not just unlikely. Every query is scoped by construction; you have to explicitly call `.unscoped` to break it (and that should be a code-review red flag). I have 6 specs that prove this guarantee.

3. **What I'm proudest of technically.** The AI classification pipeline. It calls an LLM API asynchronously through Sidekiq, has retry-with-backoff on transient failures, and **graceful fallback** — if the LLM is down, the support desk stays fully usable, the AI fields just say "AI unavailable" with the fallback reason. A production-grade SaaS shouldn't 500 its customers because a third-party vendor hiccupped.

4. **What I'd do with more time.**
   - Switch to schema-per-tenant for hard isolation (current default-scope approach is fine up to ~1000 tenants, then you want physical separation)
   - Add ActionCable for real-time ticket updates (typing indicators, new-message toasts)
   - Add Sentry / OpenTelemetry for production observability
   - Switch SQLite dev to Postgres dev so the `LATERAL` and window-function SQL in `AnalyticsQuery` is the actual code path

This narrative shows you can think like a senior engineer on day one — exactly the signal interviewers are looking for, even at the intern level.

---

## 18. Troubleshooting

### `NameError: undefined method '_assign_default_account'` on boot

You're missing the `TenantScoped` concern patch that was added during dev. Pull the latest `app/models/concerns/tenant_scoped.rb`.

### `FrozenError: can't modify frozen Array` when booting Rails 7.1

Don't add `app/services` to `config.autoload_paths` — Rails 7.1 freezes that array. Use `config.eager_load_paths` (see `config/initializers/02_eager_load_paths.rb`).

### `ActiveStorage` errors on boot

You need a `config/storage.yml`. We ship a minimal one (Disk service) so the engine boots even though we don't use ActiveStorage.

### `Could not find table 'accounts'` when running tests

The test database isn't migrated. Run:

```bash
RAILS_ENV=test bin/rails db:create db:migrate
```

### LLM API call hangs forever

You're using the `:async` adapter (in-process) which doesn't share with the request thread in some environments. Either set `LLM_API_KEY=` (forces fallback) or set up Redis + Sidekiq for proper async.

### Multi-tenant test fails after a refactor

Almost always means someone called `.unscoped` somewhere without setting `Current.account` afterward. Search the codebase:

```bash
grep -rn '\.unscoped' app/
```

Each hit should have a code comment explaining the justification.

---

## License

MIT — use it, fork it, learn from it.

## Credits

- Faraday gem for the LLM HTTP client
- tailwindcss-rails for utility-first styling
- Sidekiq for production background jobs
- OpenRouter for free-tier LLM access during development

---

**Built with care as a portfolio project targeting Ruby on Rails internship roles.**