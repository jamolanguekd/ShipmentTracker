# webhook-endpoints Specification

## Purpose

Allows API consumers to register, manage, and remove webhook endpoint subscriptions that control which shipment tracking events trigger outbound notifications.

## Requirements

### Requirement: Register a webhook endpoint
The system SHALL accept a POST request to create a new webhook endpoint registration with a target URL, a shared secret for signature verification, an optional shipment scope, optional status filters, and an active flag.

#### Scenario: Successful registration with all fields
- **WHEN** a client POSTs to `/api/v1/webhook_endpoints` with `url`, `secret`, `shipment_id`, `status_filters`, and `active`
- **THEN** the system responds with HTTP 201 and the created endpoint record including `id`, `url`, `shipment_id`, `status_filters`, `active`, and timestamps

#### Scenario: Successful registration with minimal fields
- **WHEN** a client POSTs to `/api/v1/webhook_endpoints` with only `url` and `secret`
- **THEN** the system responds with HTTP 201 with `shipment_id` as null (all shipments), `status_filters` as empty (all statuses), and `active` defaulting to true

#### Scenario: Missing required URL
- **WHEN** a client POSTs to `/api/v1/webhook_endpoints` without a `url`
- **THEN** the system responds with HTTP 422 and a JSON error object describing the missing field

#### Scenario: Missing required secret
- **WHEN** a client POSTs to `/api/v1/webhook_endpoints` without a `secret`
- **THEN** the system responds with HTTP 422 and a JSON error object describing the missing field

#### Scenario: Invalid shipment reference
- **WHEN** a client POSTs to `/api/v1/webhook_endpoints` with a `shipment_id` that does not exist
- **THEN** the system responds with HTTP 422 and a JSON error object describing the invalid reference

### Requirement: List all webhook endpoints
The system SHALL return a list of all registered webhook endpoints.

#### Scenario: List with existing endpoints
- **WHEN** a client sends GET `/api/v1/webhook_endpoints`
- **THEN** the system responds with HTTP 200 and an array of all webhook endpoint records ordered by creation date descending

#### Scenario: List with no endpoints
- **WHEN** a client sends GET `/api/v1/webhook_endpoints` and no endpoints exist
- **THEN** the system responds with HTTP 200 and an empty array

### Requirement: Retrieve a single webhook endpoint
The system SHALL return a single webhook endpoint record by its unique identifier.

#### Scenario: Existing endpoint
- **WHEN** a client sends GET `/api/v1/webhook_endpoints/:id` for an existing record
- **THEN** the system responds with HTTP 200 and the full webhook endpoint JSON representation

#### Scenario: Non-existent endpoint
- **WHEN** a client sends GET `/api/v1/webhook_endpoints/:id` for a non-existent record
- **THEN** the system responds with HTTP 404 and a JSON error body

### Requirement: Update a webhook endpoint
The system SHALL allow partial update of a webhook endpoint's mutable attributes: `url`, `secret`, `shipment_id`, `status_filters`, and `active`.

#### Scenario: Successful update
- **WHEN** a client sends PATCH `/api/v1/webhook_endpoints/:id` with valid attributes
- **THEN** the system responds with HTTP 200 and the updated endpoint record

#### Scenario: Invalid update
- **WHEN** a client sends PATCH `/api/v1/webhook_endpoints/:id` with an attribute that fails validation
- **THEN** the system responds with HTTP 422 and a JSON error object

### Requirement: Delete a webhook endpoint
The system SHALL permanently remove a webhook endpoint and all its associated delivery records when a DELETE request is received.

#### Scenario: Successful deletion
- **WHEN** a client sends DELETE `/api/v1/webhook_endpoints/:id` for an existing record
- **THEN** the system responds with HTTP 204 and no body

#### Scenario: Non-existent endpoint deletion
- **WHEN** a client sends DELETE `/api/v1/webhook_endpoints/:id` for a non-existent record
- **THEN** the system responds with HTTP 404

### Requirement: Validate status_filters values
The system SHALL constrain `status_filters` entries to the allowed shipment status values: `pending`, `in_transit`, `out_for_delivery`, `delivered`, `failed`.

#### Scenario: Invalid status filter value
- **WHEN** a client creates or updates a webhook endpoint with a `status_filters` entry outside the allowed set
- **THEN** the system responds with HTTP 422 and an error describing the invalid value
