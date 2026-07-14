# How to run the test suite locally

```bash
# 1. Install gems
bundle install

# 2. Create + migrate the test database
RAILS_ENV=test bin/rails db:create db:schema:load

# 3. Run the suite
bundle exec rspec

# 4. Lint
bundle exec rubocop
```

## Headline specs (run these in interviews)

```bash
# Tenant isolation — the most important test in the codebase
bundle exec rspec spec/models/concerns/tenant_scoped_spec.rb

# Concurrency-safe assignment (pessimistic lock)
bundle exec rspec spec/services/assignment_service_spec.rb

# AI classification + graceful fallback (no live API call)
bundle exec rspec spec/services/ticket_classifier_service_spec.rb

# Raw SQL analytics
bundle exec rspec spec/services/analytics_query_spec.rb
```

All specs stub the LLM via WebMock, so no API key is required.