# Deployment guide

PulseDesk can be deployed to any PaaS that supports Ruby + Sidekiq + PostgreSQL + Redis.
The recommended providers are **Render** and **Fly.io** because they both support
`Procfile`-based deployments and have free Redis add-ons.

---

## Render (easiest)

1. Push the repo to GitHub.
2. On https://render.com, create a new **Blueprint** and point it at the repo.
   The repo includes a `render.yaml` (optional) that you can use.
3. Render will detect the `Procfile` and create two services:
   - `pulsedesk-web`     → `bundle exec puma -C config/puma.rb`
   - `pulsedesk-worker`  → `bundle exec sidekiq -C config/sidekiq.yml`
4. Provision:
   - A managed PostgreSQL instance (free tier is fine)
   - A managed Redis instance (free tier is fine)
5. Set environment variables on **both** services:
   ```
   DATABASE_HOST=...
   DATABASE_PORT=5432
   DATABASE_USERNAME=...
   DATABASE_PASSWORD=...
   DATABASE_NAME=pulsedesk_production
   REDIS_URL=redis://...
   SECRET_KEY_BASE=<output of `bin/rails secret`>
   RAILS_MASTER_KEY=<from config/master.key>
   RAILS_ENV=production
   LLM_PROVIDER=openrouter
   LLM_API_KEY=sk-or-v1-...
   LLM_MODEL=meta-llama/llama-3.1-8b-instruct:free
   ```
6. Render runs `bundle exec rails db:migrate db:seed` automatically via the
   `release` phase in the Procfile.

---

## Fly.io

```bash
fly launch                              # creates fly.toml + Dockerfile (auto-detected)
fly postgres create                      # managed PG
fly redis create                         # managed Redis
fly secrets set DATABASE_HOST=... \
                DATABASE_PASSWORD=... \
                REDIS_URL=redis://... \
                SECRET_KEY_BASE=$(bin/rails secret) \
                LLM_API_KEY=sk-or-v1-...
fly deploy
```

To scale workers:
```bash
fly scale count worker=1
```

---

## Health check

`GET /up` returns 200 if the app boots correctly. Configure your provider to
poll `/up` every 30s.

---

## Local Docker (optional)

A `Dockerfile` is **not** committed by default (Rails 7.1 generates a
`Dockerfile` if you run `rails new --docker`). To run with Docker manually:

```bash
docker build -t pulsedesk .
docker run -p 3000:3000 \
  -e DATABASE_HOST=host.docker.internal \
  -e REDIS_URL=redis://host.docker.internal:6379/0 \
  -e LLM_API_KEY=... \
  pulsedesk
```