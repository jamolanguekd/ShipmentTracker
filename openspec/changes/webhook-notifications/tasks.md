# Tasks

## 1. Database migrations

- [x] 1.1 Create migration for `webhook_endpoints` table with columns: `url` (string, NOT NULL), `secret` (string, NOT NULL), `shipment_id` (bigint, FK nullable), `status_filters` (string array, default `{}`), `active` (boolean, NOT NULL, default true), and timestamps. Add foreign key to shipments. Verify: `bin/rails db:migrate` succeeds and `db/schema.rb` shows the table with correct columns and constraints.
- [x] 1.2 Create migration for `webhook_deliveries` table with columns: `webhook_endpoint_id` (bigint, FK NOT NULL), `tracking_event_id` (bigint, FK NOT NULL), `payload` (jsonb, NOT NULL), `response_code` (integer, nullable), `response_body` (text, nullable), `status` (integer, NOT NULL, default 0), `attempts` (integer, NOT NULL, default 0), `delivered_at` (datetime, nullable), `next_retry_at` (datetime, nullable), and timestamps. Add composite index on `(webhook_endpoint_id, created_at)`. Add foreign keys to webhook_endpoints and tracking_events. Verify: `bin/rails db:migrate` succeeds and `db/schema.rb` shows the table with correct columns, index, and foreign keys.

## 2. Models

- [x] 2.1 Create `WebhookEndpoint` model with associations (`belongs_to :shipment, optional: true`, `has_many :webhook_deliveries, dependent: :destroy`), validations (`url` and `secret` presence, `status_filters` inclusion validation against allowed statuses, `shipment_id` foreign key validation), and the `active` scope. Add factory. Verify: `rspec spec/models/webhook_endpoint_spec.rb` passes with tests for associations, validations, and the status_filters custom validation.
- [x] 2.2 Create `WebhookDelivery` model with associations (`belongs_to :webhook_endpoint`, `belongs_to :tracking_event`), enum for status (`pending: 0, success: 1, failed: 2`), and response_body truncation (cap at 1024 bytes on write via a before_validation callback). Add factory. Verify: `rspec spec/models/webhook_delivery_spec.rb` passes with tests for associations, enum values, and response_body truncation.

## 3. WebhookEndpoint CRUD API

- [x] 3.1 Add routes: `resources :webhook_endpoints` under the `api/v1` namespace, with nested `resources :deliveries, only: [:index], controller: 'webhook_deliveries'`. Verify: `bin/rails routes | grep webhook` shows all expected routes.
- [x] 3.2 Create `Api::V1::WebhookEndpointsController` with `index` (ordered by created_at desc), `show`, `create`, `update`, and `destroy` actions. Follow the same patterns as `ShipmentsController`. Verify: `rspec spec/requests/api/v1/webhook_endpoints_spec.rb` passes covering all spec scenarios — CRUD success cases, validation errors (missing url, missing secret, invalid shipment_id, invalid status_filters), and 404 on missing records.

## 4. WebhookDelivery read API

- [x] 4.1 Create `Api::V1::WebhookDeliveriesController` with `index` action only, scoped to the parent webhook endpoint, ordered by created_at desc. Verify: `rspec spec/requests/api/v1/webhook_deliveries_spec.rb` passes covering list with deliveries, empty list, and 404 for non-existent endpoint.

## 5. Dispatch service

- [x] 5.1 Create `WebhookDispatchService` in `app/services/webhook_dispatch_service.rb`. It takes a `TrackingEvent`, queries active `WebhookEndpoint` records matching by `shipment_id` (null or matching) and `status_filters` (empty or including the event's status), builds the payload JSON (event + shipment data per design), creates a `WebhookDelivery` record per match with status `pending`, and enqueues `WebhookDeliveryJob` for each. Verify: `rspec spec/services/webhook_dispatch_service_spec.rb` passes with tests for: matching by shipment scope, matching by status filter, wildcard endpoint, skipping inactive endpoints, skipping non-matching status filters, creating delivery records, and enqueuing jobs.

## 6. Delivery job

- [x] 6.1 Create `WebhookDeliveryJob` in `app/jobs/webhook_delivery_job.rb`. It takes a `WebhookDelivery` id, POSTs the payload to the endpoint URL via `Net::HTTP` with `Content-Type: application/json`, `X-Webhook-Signature` header (HMAC-SHA256 hex digest of body using endpoint secret), 10s open timeout, and 15s read timeout. On 2xx: update delivery to `success` with response_code, response_body (truncated), delivered_at. On non-2xx or timeout: increment attempts, update response_code/response_body, and re-enqueue with backoff delay (30s, 2m, 10m, 1h) if under 5 attempts, otherwise mark `failed`. Verify: `rspec spec/jobs/webhook_delivery_job_spec.rb` passes with tests for: successful delivery, failed delivery with retry scheduling, max attempts exhaustion, timeout handling, HMAC signature correctness, and response body truncation.

## 7. Controller integration

- [x] 7.1 Add explicit `WebhookDispatchService.call(@tracking_event)` call in `TrackingEventsController#create` after successful save. Verify: `rspec spec/requests/api/v1/tracking_events_spec.rb` passes (create a request spec if one does not exist) confirming that creating a tracking event with a matching webhook endpoint enqueues a delivery job, and that the tracking event response itself is unchanged.

## 8. End-to-end verification

- [x] 8.1 Run full test suite (`bundle exec rspec`) and verify all tests pass with zero failures. Verify: exit code 0 and no failures or errors in output.
