# Design

## Context

Greenfield Rails 6.1 API-only application targeting Ruby 3.1.6. No existing code to migrate. The application will be containerized from day one; the database is a separate PostgreSQL container. See `proposal.md` for motivation.

## Goals / Non-Goals

**Goals:**
- Minimal, idiomatic Rails 6.1 API app with no view layer
- Two domain resources: `Shipment` and `TrackingEvent` (nested under shipment)
- PostgreSQL via Docker Compose, environment-variable driven connection
- RSpec request specs covering happy path and error cases for each endpoint
- RSpec model unit tests covering validations and associations
- Single-command local bootstrap: `docker compose up`

**Non-Goals:**
- Authentication or authorization (future change)
- Background jobs or webhooks
- Non-PostgreSQL database support
- Production deployment configuration (Kubernetes, CI pipelines)
- Admin UI or frontend

## Decisions

### Rails API-only mode
Use `rails new --api` to generate the application. This removes ActionView, ActionMailer, and middleware not needed by a pure JSON API, keeping the container image smaller and boot time faster.

**Alternatives considered**: Full Rails with `respond_to :json` — rejected because the overhead of unused middleware adds no value and could introduce confusion later.

### RSpec + FactoryBot over Minitest
RSpec is the test framework; FactoryBot provides test data factories. RSpec's DSL reads closer to the scenario language in the specs, making traceability between spec files and test files straightforward.

**Alternatives considered**: Rails default Minitest — viable but RSpec is more conventional for new Rails API projects and better integrates with `shoulda-matchers` for model validations.

### Status field as enum
Both `Shipment#status` and `TrackingEvent#status` use ActiveRecord `enum`, backed by an integer column. This enforces the constrained value set at the model layer and generates scope helpers.

**Alternatives considered**: String column with a validation — functionally equivalent but enum gives free query scopes and a more explicit contract between DB and code.

### TrackingEvent immutability via routing
The `tracking_events` route is registered with `only: [:index, :create]`, making update/delete routes respond with 404 (route not found → 405 by convention). No extra controller logic required.

**Alternatives considered**: `before_action` guard in the controller — unnecessary when the router already prevents those routes from existing.

### Docker Compose topology
Two services: `app` (Rails, port 3000) and `db` (PostgreSQL 15). The `app` service depends on `db` and reads database credentials from environment variables supplied via `.env` (gitignored; `.env.example` committed).

**Alternatives considered**: Single container with embedded Postgres — rejected because it couples the app and DB lifecycles, complicating restarts and data persistence during development.

### database.yml
Connection is driven by `DATABASE_URL` environment variable, with individual `host`/`port`/`username`/`password` fields as fallbacks. This keeps the `docker-compose.yml` and any future deployment environment the single source of truth.

## Risks / Trade-offs

- **Rails 6.1 + Ruby 3.1 compatibility**: Rails 6.1 officially supports Ruby 3.0; Ruby 3.1 introduced keyword argument changes that required patches in several gems. → Mitigation: pin gem versions explicitly in `Gemfile.lock` and run `bundle exec rspec` inside the container to catch any breakage early.
- **Enum integer storage**: If the allowed status values need to be reordered, an integer-backed enum makes migration non-trivial. → Mitigation: treat the enum order as append-only; add new statuses only at the end. Document this constraint in the model.
- **No authentication**: All endpoints are publicly accessible. → Accepted for now; authentication is explicitly out of scope and should be the next change once the core API is stable.

## Migration Plan

1. Generate Rails app with `--api --database=postgresql`
2. Add Gemfile dependencies (rspec-rails, factory_bot_rails, shoulda-matchers, pg, rack-cors)
3. Create `Dockerfile` and `docker-compose.yml`
4. Generate `Shipment` and `TrackingEvent` models and migrations
5. Implement controllers and routes
6. Write model unit tests and request specs
7. Verify `docker compose up` + `docker compose exec app bundle exec rspec` passes cleanly

Rollback: delete the generated Rails app directory. No production data or existing system is affected.
