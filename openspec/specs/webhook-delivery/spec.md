# webhook-delivery Specification

## Purpose

Handles asynchronous delivery of HMAC-signed webhook payloads to registered endpoints when tracking events are recorded, with retry logic and a read-only delivery log for consumers to inspect delivery history.

## Requirements

### Requirement: Dispatch webhooks on tracking event creation
The system SHALL dispatch webhook notifications to all matching active endpoints when a tracking event is successfully created. Matching means the endpoint's `shipment_id` is null (wildcard) or equals the tracking event's shipment, AND the endpoint's `status_filters` is empty (all statuses) or includes the tracking event's status.

#### Scenario: Endpoint matches by shipment and status
- **WHEN** a tracking event with status `delivered` is created for shipment 42, and an active endpoint exists with `shipment_id` 42 and `status_filters` including `delivered`
- **THEN** the system enqueues an asynchronous delivery to that endpoint

#### Scenario: Wildcard endpoint matches all shipments
- **WHEN** a tracking event is created for any shipment, and an active endpoint exists with `shipment_id` null and empty `status_filters`
- **THEN** the system enqueues an asynchronous delivery to that endpoint

#### Scenario: Endpoint does not match status filter
- **WHEN** a tracking event with status `in_transit` is created, and an active endpoint exists with `status_filters` set to `["delivered", "failed"]`
- **THEN** the system SHALL NOT enqueue a delivery to that endpoint

#### Scenario: Inactive endpoint is skipped
- **WHEN** a tracking event is created and a matching endpoint exists with `active` set to false
- **THEN** the system SHALL NOT enqueue a delivery to that endpoint

### Requirement: Sign outbound webhook payloads
The system SHALL sign each outbound webhook POST body using HMAC-SHA256 with the endpoint's `secret` and include the hex-encoded signature in the `X-Webhook-Signature` HTTP header.

#### Scenario: Signature header is present
- **WHEN** the system delivers a webhook payload to an endpoint
- **THEN** the outbound HTTP request includes an `X-Webhook-Signature` header whose value is the HMAC-SHA256 hex digest of the request body using the endpoint's secret

### Requirement: Retry failed deliveries with exponential backoff
The system SHALL retry a failed delivery up to 5 total attempts with exponential backoff intervals. A delivery is considered failed when the target returns a non-2xx HTTP status code or the request times out.

#### Scenario: First attempt fails, retry is scheduled
- **WHEN** a webhook delivery attempt receives a non-2xx response
- **THEN** the system schedules a retry with an exponentially increasing delay and increments the attempt count

#### Scenario: Maximum attempts exhausted
- **WHEN** a webhook delivery has been attempted 5 times without a 2xx response
- **THEN** the system marks the delivery as `failed` and does not schedule further retries

#### Scenario: Successful delivery on retry
- **WHEN** a webhook delivery retry receives a 2xx response
- **THEN** the system marks the delivery as `success` and records the response code and delivered timestamp

### Requirement: Record delivery attempts
The system SHALL create a webhook delivery record for each dispatch, capturing the payload sent, HTTP response code, response body (truncated to 1024 bytes), delivery status, attempt count, and timestamps.

#### Scenario: Delivery record created on dispatch
- **WHEN** the system dispatches a webhook for a tracking event to an endpoint
- **THEN** a `WebhookDelivery` record is created with status `pending`, attempt count 0, and the serialized JSON payload

#### Scenario: Delivery record updated after attempt
- **WHEN** a delivery attempt completes (success or failure)
- **THEN** the delivery record's `response_code`, `response_body`, `attempts`, and `status` are updated

### Requirement: List delivery records for an endpoint
The system SHALL return delivery records for a given webhook endpoint, ordered by creation date descending.

#### Scenario: List deliveries for an endpoint
- **WHEN** a client sends GET `/api/v1/webhook_endpoints/:webhook_endpoint_id/deliveries`
- **THEN** the system responds with HTTP 200 and an array of delivery records for that endpoint ordered by creation date descending

#### Scenario: List deliveries for non-existent endpoint
- **WHEN** a client sends GET `/api/v1/webhook_endpoints/:webhook_endpoint_id/deliveries` for a non-existent endpoint
- **THEN** the system responds with HTTP 404

#### Scenario: No deliveries exist
- **WHEN** a client sends GET for deliveries of an endpoint that has no delivery records
- **THEN** the system responds with HTTP 200 and an empty array
