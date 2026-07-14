# Security

PulseDesk treats tenant isolation as a **first-class security requirement**.
This document explains the design and the audit checklist for code review.

## Threat model

| Threat | Mitigation |
|---|---|
| Tenant A queries Tenant B's records | `TenantScoped` default scope on every tenant-owned model |
| Direct URL access to another tenant's record | `find()` inside tenant scope returns `RecordNotFound`; cross-tenant `update` is silently ignored |
| Forgetting to set `Current.account` in a worker | Workers must explicitly set `Current.account = ticket.account`; tests assert this |
| SQL injection in analytics queries | All values are bound via `sanitize_sql_array`, never interpolated |
| Password leak | `bcrypt` via `has_secure_password`; passwords never logged (see `filter_parameter_logging`) |
| API key leak | Loaded from ENV; logged values filtered; `.env` is gitignored |
| Session hijacking | Session store rotated on login (`reset_session`); CSRF tokens enabled |
| Brute-force login | Out of scope for intern demo; production should add `rack-attack` |

## Code review checklist

When reviewing a PR that touches a tenant-owned model:

- [ ] Does the model `include TenantScoped`?
- [ ] Does the migration add `account_id`?
- [ ] Is there a composite index on `(account_id, …)` for the most common filter?
- [ ] Does the spec create data in two accounts and prove isolation?
- [ ] For workers: does the job set `Current.account` before any writes?

## Reporting a vulnerability

This is a portfolio project — please open a GitHub issue with the label
`security` if you spot a problem.