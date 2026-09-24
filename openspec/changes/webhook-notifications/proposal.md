# Proposal

## Why

API consumers have no way to know when a shipment's status changes without polling. Webhook notifications let consumers register a callback URL and receive real-time POSTs when tracking events are recorded, eliminating polling and enabling downstream automation (alerts, dashboards, partner integrations).

## What Changes

- **New `WebhookEndpoint` model and CRUD API** — consumers register URLs they want to receive notifications at, with an HMAC secret for signature verification, optional per-shipment scoping, and status filters.
- **New `WebhookDelivery` model and read API** — an append-only delivery log per endpoint, recording payload, response, attempt count, and delivery status.
- **New `WebhookDeliveryJob`** — an ActiveJob that POSTs the signed payload to the endpoint URL with exponential backoff retry (up to 5 attempts).
- **New `WebhookDispatchService`** — called explicitly from `TrackingEventsController#create` after a successful save. Finds matching active endpoints (by shipment scope and status filters) and enqueues a delivery job per match.
- **HMAC-SHA256 request signing** — each outbound POST includes a signature header so receivers can verify authenticity.

## Capabilities

### New Capabilities

- `webhook-endpoints`: CRUD management of webhook endpoint registrations, including URL, secret, per-shipment scoping, status filters, and active toggle.
- `webhook-delivery`: Asynchronous webhook delivery with HMAC-signed payloads, delivery logging, exponential backoff retry, and a read-only delivery log API.

### Modified Capabilities

_None. The tracking event creation flow gains a dispatch call in the controller, but the tracking event API's own requirements (request/response contract, validation, append-only semantics) are unchanged._

## Impact

- **New database tables**: `webhook_endpoints`, `webhook_deliveries`
- **New controllers**: `Api::V1::WebhookEndpointsController`, `Api::V1::WebhookDeliveriesController` (read-only)
- **Modified controller**: `Api::V1::TrackingEventsController#create` — adds explicit call to `WebhookDispatchService` after save
- **New routes**: RESTful endpoints under `/api/v1/webhook_endpoints` and nested `/deliveries`
- **New dependencies**: None expected — `net/http` from stdlib is sufficient for outbound POST; ActiveJob is already available in Rails 6
- **Background processing**: Requires an ActiveJob backend (e.g., Sidekiq or Async adapter for dev/test)
