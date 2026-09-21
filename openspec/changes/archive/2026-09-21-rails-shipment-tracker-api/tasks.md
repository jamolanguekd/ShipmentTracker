# Tasks

## 1. Project Bootstrap

- [x] 1.1 Generate a new Rails 6.1 API-only app with PostgreSQL adapter (`rails new . --api --database=postgresql --skip-git`) and verify the directory structure contains `app/`, `config/`, `Gemfile`
- [x] 1.2 Pin Ruby version to 3.1.6 in `.ruby-version` (already present) and verify `ruby --version` matches inside the app
- [x] 1.3 Add gems to `Gemfile`: `rspec-rails`, `factory_bot_rails`, `shoulda-matchers`, `rack-cors` (development/test groups as appropriate) and run `bundle install` to verify no resolution errors

## 2. Docker Setup

- [x] 2.1 Create `Dockerfile` using `ruby:3.1.6-alpine` as base, install build dependencies, copy `Gemfile*`, run `bundle install`, copy app source, expose port 3000, and set `CMD ["rails", "server", "-b", "0.0.0.0"]`; verify `docker build .` succeeds
- [x] 2.2 Create `docker-compose.yml` with two services — `db` (postgres:15) and `app` (build from current dir, port 3000→3000, depends on `db`, env vars from `.env`) — and verify `docker compose config` validates without errors
- [x] 2.3 Create `.env.example` with `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `DATABASE_URL` placeholders; create a `.env` from it (gitignored) with working local values
- [x] 2.4 Update `config/database.yml` to read `DATABASE_URL` environment variable (primary source) with individual `host`/`port`/`username`/`password` fields as fallback; verify `docker compose run app rails db:create` succeeds

## 3. Models & Migrations

- [x] 3.1 Generate `Shipment` model with columns: `reference_number:string` (unique, not null), `origin:string` (not null), `destination:string` (not null), `carrier:string`, `status:integer` (default 0); verify migration runs with `rails db:migrate`
- [x] 3.2 Add ActiveRecord enum on `Shipment` for `status`: `{ pending: 0, in_transit: 1, out_for_delivery: 2, delivered: 3, failed: 4 }` and add a uniqueness index on `reference_number` in the migration
- [x] 3.3 Add validations to `Shipment`: `reference_number` presence and uniqueness, `origin` presence, `destination` presence, `status` inclusion in enum values; verify model loads without error
- [x] 3.4 Generate `TrackingEvent` model with columns: `shipment_id:references` (not null, foreign key), `status:integer` (not null), `location:string`, `occurred_at:datetime` (not null), `notes:text`; verify migration runs
- [x] 3.5 Add ActiveRecord enum on `TrackingEvent` for `status` (same values as `Shipment`), add `belongs_to :shipment` with `presence: true`, add validations for `status` and `occurred_at` presence; verify model loads without error

## 4. Controllers & Routes

- [x] 4.1 Create `Api::V1::ShipmentsController` with `index`, `show`, `create`, `update`, `destroy` actions; each action responds with JSON, uses `render json:` with appropriate HTTP status codes; verify `rails routes` lists the 5 shipment routes under `api/v1`
- [x] 4.2 Implement strong parameters for `Shipment` (permit `reference_number`, `origin`, `destination`, `carrier`, `status`); verify invalid keys are stripped
- [x] 4.3 Create `Api::V1::TrackingEventsController` with `index` and `create` actions only, scoped under `shipments`; verify `rails routes` lists exactly 2 tracking event routes and no update/delete routes exist (returning 404 for those)
- [x] 4.4 Implement strong parameters for `TrackingEvent` (permit `status`, `location`, `occurred_at`, `notes`); verify invalid keys are stripped
- [x] 4.5 Add a `rescue_from ActiveRecord::RecordNotFound` in `ApplicationController` that renders `{ error: "Not found" }` with HTTP 404; verify unreachable records return 404 JSON
- [x] 4.6 Configure `config/routes.rb` with namespace `api` → `v1` → resources `shipments` (full CRUD) nested resources `tracking_events` (only index, create); verify `rails routes` output matches expected structure

## 5. CORS & Application Config

- [x] 5.1 Configure `rack-cors` in `config/initializers/cors.rb` to allow all origins in development (restrict in production); verify the initializer loads without error on `rails server` start

## 6. Test Infrastructure

- [x] 6.1 Run `rails generate rspec:install` and verify `.rspec`, `spec/spec_helper.rb`, and `spec/rails_helper.rb` are created
- [x] 6.2 Configure `FactoryBot` in `spec/rails_helper.rb` (include `FactoryBot::Syntax::Methods`) and `Shoulda::Matchers`; verify `bundle exec rspec` runs with 0 examples and 0 failures
- [x] 6.3 Create `spec/factories/shipments.rb` with a valid `Shipment` factory (unique `reference_number` via sequence); verify `FactoryBot.create(:shipment)` succeeds in a Rails console or test

## 7. Model Unit Tests

- [x] 7.1 Write `spec/models/shipment_spec.rb` covering: presence validations for `reference_number`, `origin`, `destination`; uniqueness of `reference_number`; enum values; `has_many :tracking_events`; verify all pass with `bundle exec rspec spec/models/shipment_spec.rb`
- [x] 7.2 Create `spec/factories/tracking_events.rb` with a valid `TrackingEvent` factory associated to a shipment
- [x] 7.3 Write `spec/models/tracking_event_spec.rb` covering: `belongs_to :shipment`; presence validations for `status` and `occurred_at`; enum values; verify all pass with `bundle exec rspec spec/models/tracking_event_spec.rb`

## 8. Request Specs — Shipments

- [x] 8.1 Write `spec/requests/api/v1/shipments_spec.rb` — `POST /api/v1/shipments`: valid payload → 201 with full JSON body; missing required field → 422 with error JSON
- [x] 8.2 Add `GET /api/v1/shipments/:id` request spec: existing record → 200 with record JSON; unknown id → 404 with error JSON
- [x] 8.3 Add `GET /api/v1/shipments` request spec: returns 200 with array of records ordered by `created_at` descending
- [x] 8.4 Add `PATCH /api/v1/shipments/:id` request spec: valid payload → 200 with updated record; invalid value → 422 with error JSON
- [x] 8.5 Add `DELETE /api/v1/shipments/:id` request spec: existing record → 204 no body; non-existent → 404
- [x] 8.6 Verify all shipment request specs pass: `bundle exec rspec spec/requests/api/v1/shipments_spec.rb`

## 9. Request Specs — Tracking Events

- [x] 9.1 Write `spec/requests/api/v1/tracking_events_spec.rb` — `POST /api/v1/shipments/:shipment_id/tracking_events`: valid payload → 201 with event JSON; non-existent shipment → 404; missing required field → 422
- [x] 9.2 Add `GET /api/v1/shipments/:shipment_id/tracking_events` request spec: returns 200 with events ordered by `occurred_at` ascending; empty list → 200 with `[]`; non-existent shipment → 404
- [x] 9.3 Verify PATCH and PUT to a tracking event path return 404 (route does not exist)
- [x] 9.4 Verify all tracking event request specs pass: `bundle exec rspec spec/requests/api/v1/tracking_events_spec.rb`

## 10. End-to-End Docker Verification

- [x] 10.1 Run `docker compose build` and verify the image builds without errors
- [x] 10.2 Run `docker compose run app rails db:create db:migrate` and verify both databases (development, test) are created
- [x] 10.3 Run `docker compose run app bundle exec rspec` and verify the full test suite passes with 0 failures
- [x] 10.4 Start the stack with `docker compose up` and verify `curl http://localhost:3000/api/v1/shipments` returns HTTP 200 with `[]`
