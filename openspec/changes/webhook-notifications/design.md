# Design

## Context

See proposal.md for motivation. The app is a Rails 6.1 API-only application backed by PostgreSQL. ActiveJob is already loaded but no queue adapter beyond the default (async/inline) is configured. The codebase has two models (`Shipment`, `TrackingEvent`), two API controllers under `Api::V1`, and uses RSpec with FactoryBot for testing. There are no service objects, background jobs, or outbound HTTP calls yet.

## Goals / Non-Goals

**Goals:**
- Introduce webhook endpoint CRUD with per-shipment scoping and status filtering
- Deliver signed payloads asynchronously via ActiveJob with retry
- Provide a delivery log API for debugging
- Keep the dispatch call explicit in the controller (no hidden callbacks)

**Non-Goals:**
- Authentication/authorization for the webhook management API (same as existing endpoints — no auth layer yet)
- Pagination on any endpoint (not implemented on existing endpoints either)
- Webhook payload schema versioning
- Rate limiting outbound webhook deliveries
- UI or dashboard for webhook management

## Decisions

### 1. Database schema for `webhook_endpoints`

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | bigint | PK |
| `url` | string | NOT NULL |
| `secret` | string | NOT NULL |
| `shipment_id` | bigint | FK nullable (null = all shipments) |
| `status_filters` | string[] | PostgreSQL array, default `{}` (empty = all statuses) |
| `active` | boolean | NOT NULL, default true |
| `created_at` | datetime | NOT NULL |
| `updated_at` | datetime | NOT NULL |

**Why PostgreSQL array for `status_filters`**: The project already uses PostgreSQL. A native array column avoids a join table for a small, fixed set of values. The filter set is the 5 shipment statuses — it will not grow unbounded. Alternative considered: a separate `webhook_status_filters` join table. Rejected as over-normalized for ≤5 values per row.

**Why nullable `shipment_id`**: Null means "subscribe to all shipments." This keeps the matching query simple: `WHERE shipment_id IS NULL OR shipment_id = ?`. Alternative: a separate boolean `all_shipments` flag. Rejected — null-as-wildcard is a well-understood pattern and avoids a redundant column.

### 2. Database schema for `webhook_deliveries`

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | bigint | PK |
| `webhook_endpoint_id` | bigint | FK NOT NULL |
| `tracking_event_id` | bigint | FK NOT NULL |
| `payload` | jsonb | NOT NULL |
| `response_code` | integer | nullable |
| `response_body` | text | nullable, truncated to 1024 bytes on write |
| `status` | integer | NOT NULL, enum: pending=0, success=1, failed=2 |
| `attempts` | integer | NOT NULL, default 0 |
| `delivered_at` | datetime | nullable |
| `next_retry_at` | datetime | nullable |
| `created_at` | datetime | NOT NULL |
| `updated_at` | datetime | NOT NULL |

Index on `(webhook_endpoint_id, created_at)` for the delivery log listing.

**Why `jsonb` for payload**: Stores the exact JSON sent to the consumer. Enables querying delivery contents if needed later without parsing. Alternative: `text` column with serialized JSON. `jsonb` is idiomatic PostgreSQL and lets the DB validate structure.

### 3. Dispatch is explicit in the controller

`TrackingEventsController#create` calls `WebhookDispatchService.call(tracking_event)` after a successful save. The dispatch service is a plain Ruby class under `app/services/`.

**Why explicit over callback**: The user chose this during exploration. Callbacks on `TrackingEvent` would fire on all creates including seeds, tests, and console usage. An explicit call keeps the side effect visible and controllable.

### 4. Outbound HTTP via `Net::HTTP`

Use Ruby stdlib `Net::HTTP` with a 10-second open timeout and 15-second read timeout. No new gem dependency.

**Why not Faraday/HTTParty**: The app has zero HTTP client gems today. For a single outbound POST with fixed headers, `Net::HTTP` is sufficient. Adding a gem is easy later if patterns grow.

### 5. HMAC-SHA256 signing

Compute `OpenSSL::HMAC.hexdigest("SHA256", endpoint.secret, request_body)` and set it as the `X-Webhook-Signature` header. The consumer verifies by computing the same digest with their copy of the secret.

### 6. Retry strategy

Exponential backoff schedule: attempt 1 at +30s, attempt 2 at +2m, attempt 3 at +10m, attempt 4 at +1h. 5 total attempts (1 initial + 4 retries). After the 5th failure, status is set to `failed` permanently.

Implemented via ActiveJob's `retry_on` or manual re-enqueue with `set(wait:)`. The job reads `attempts` from the delivery record to pick the delay.

**Why not ActiveJob's built-in retry**: ActiveJob's `retry_on` resets the job state on each retry, making it harder to track attempt count in the delivery record. Manual re-enqueue with `set(wait: delay)` gives full control over the `WebhookDelivery` record's state between attempts.

### 7. Webhook payload structure

```json
{
  "event": "tracking_event.created",
  "delivered_at": "2024-01-15T10:30:00Z",
  "data": {
    "tracking_event": {
      "id": 1,
      "shipment_id": 42,
      "status": "delivered",
      "location": "Los Angeles, CA",
      "occurred_at": "2024-01-15T10:00:00Z",
      "notes": "Left at front door",
      "created_at": "2024-01-15T10:00:05Z"
    },
    "shipment": {
      "id": 42,
      "reference_number": "REF-000001",
      "origin": "New York, NY",
      "destination": "Los Angeles, CA",
      "carrier": "FedEx",
      "status": "delivered"
    }
  }
}
```

Includes both the tracking event and the parent shipment so the consumer has full context without a follow-up API call.

### 8. ActiveJob queue adapter for development/test

Use the `:async` adapter (Rails default) for development and `:test` adapter for test. No new gem needed. Production would use Sidekiq or similar, but configuring that is out of scope.

## Risks / Trade-offs

- **Secret stored in plaintext** → Acceptable for a training app. Production would encrypt at rest. Documenting as a known limitation, not solving it now.
- **No authentication on webhook management API** → Same as all existing endpoints. A future auth change would cover this uniformly.
- **Delivery volume** → A wildcard endpoint with no status filters receives a delivery for every tracking event across all shipments. No rate limiting is in scope, so a high-traffic scenario could overwhelm a consumer. Acceptable for training scope.
- **Response body truncation** → Capped at 1024 bytes to avoid storing large error pages. Enough for debugging; consumers who need full responses should log on their side.
- **Cascade delete** → Deleting a webhook endpoint destroys its delivery records (`dependent: :destroy`). This is intentional — delivery history is only meaningful in context of its endpoint.
