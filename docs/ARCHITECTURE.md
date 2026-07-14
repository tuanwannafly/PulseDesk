# Architecture

```
                                ┌──────────────────────┐
       Browser  ──HTTP──►       │   Rails (Puma)       │
                                │   ApplicationCtrl    │
                                │   set Current.account│
                                └──────────┬───────────┘
                                           │ SQL
                                ┌──────────▼───────────┐
                                │   PostgreSQL         │
                                │   (shared DB,        │
                                │    account_id-scoped)│
                                └──────────────────────┘

       Ticket created ──► ActiveJob ──► Redis ──► Sidekiq worker
                                                    │
                                                    ▼
                                          TicketClassifierService
                                          ──HTTP──► OpenRouter / Groq
                                          ◄──JSON── { summary, sentiment, priority }
                                                    │
                                                    ▼
                                          UPDATE tickets SET ai_summary=…

       Two agents click "Claim" simultaneously:
            Thread A: BEGIN; SELECT … FOR UPDATE; UPDATE …; COMMIT;
            Thread B: blocks ──────────────────────────────► sees row locked → returns "already assigned"
```

## Multi-tenant strategy

We use **shared schema with `account_id` discriminator**. Every tenant-owned
model includes `TenantScoped`, which installs a `default_scope` filtering by
`Current.account&.id`. Because `Current.account` is set in
`ApplicationController#set_current_attributes` for every request, the scoping
is **automatic** — controllers never need to thread `account_id` through.

If `Current.account` is `nil` (e.g. inside a worker without context), the scope
returns an empty relation rather than leaking data.

Background jobs explicitly set `Current.account = ticket.account` before doing
writes — see `TicketClassificationJob#perform`.

## Why not schema-per-tenant?

For an intern-level demo, shared schema is the right trade-off:

| | Shared schema | Schema-per-tenant |
|---|---|---|
| Ops complexity | low | high (migrations x N) |
| Onboarding new tenant | trivial | manual schema copy |
| Cross-tenant analytics | easy | painful |
| Risk of data leak | medium (mitigated by `TenantScoped`) | low |

The single biggest risk is a developer forgetting to use the default scope.
We mitigate that with:

1. `TenantScoped` default scope on every tenant-owned model.
2. The headline spec `spec/models/concerns/tenant_scoped_spec.rb` proving
   isolation across accounts.
3. Request specs `spec/requests/ticket_lifecycle_spec.rb` proving direct URL
   access to another tenant's records raises `RecordNotFound`.

If/when PulseDesk grows to >1000 tenants or one tenant needs >1M tickets,
schema-per-tenant (or even DB-per-tenant) becomes worth the extra complexity.