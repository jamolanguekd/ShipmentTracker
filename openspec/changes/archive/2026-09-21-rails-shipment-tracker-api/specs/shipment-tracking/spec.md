# Spec Delta

## Purpose

Provides an append-only log of status events for a given shipment, enabling clients to record carrier updates and retrieve the full tracking history in chronological order.

## ADDED Requirements

### Requirement: Record a tracking event
The system SHALL accept a POST request to append a new status event to a shipment's tracking history.

#### Scenario: Successful event creation
- **WHEN** a client POSTs a valid event payload to `/api/v1/shipments/:shipment_id/tracking_events`
- **THEN** the system responds with HTTP 201 and the created event record including `id`, `shipment_id`, `status`, `location`, `occurred_at`, `notes`, and `created_at`

#### Scenario: Invalid shipment reference
- **WHEN** a client POSTs a tracking event for a `shipment_id` that does not exist
- **THEN** the system responds with HTTP 404

#### Scenario: Missing required event field
- **WHEN** a client POSTs a tracking event without a required field (e.g., `status` or `occurred_at`)
- **THEN** the system responds with HTTP 422 and a JSON error object describing the missing field

### Requirement: Retrieve tracking history
The system SHALL return the full ordered list of tracking events for a given shipment.

#### Scenario: Chronological event listing
- **WHEN** a client sends GET `/api/v1/shipments/:shipment_id/tracking_events`
- **THEN** the system responds with HTTP 200 and an array of all events for that shipment, ordered by `occurred_at` ascending

#### Scenario: No events recorded
- **WHEN** a client requests events for a shipment that has no tracking events
- **THEN** the system responds with HTTP 200 and an empty array

#### Scenario: Shipment not found for event listing
- **WHEN** a client requests events for a `shipment_id` that does not exist
- **THEN** the system responds with HTTP 404

### Requirement: Tracking event status field
The system SHALL constrain the `status` field on a tracking event to the same allowed values as the shipment status: `pending`, `in_transit`, `out_for_delivery`, `delivered`, `failed`.

#### Scenario: Invalid event status
- **WHEN** a client records an event with a `status` outside the allowed set
- **THEN** the system responds with HTTP 422 and an error describing the invalid value

### Requirement: Immutability of tracking events
The system SHALL NOT allow existing tracking events to be updated or deleted once recorded.

#### Scenario: Attempt to update an event
- **WHEN** a client sends PATCH or PUT to a tracking event resource
- **THEN** the system responds with HTTP 405

#### Scenario: Attempt to delete an event
- **WHEN** a client sends DELETE to a tracking event resource
- **THEN** the system responds with HTTP 405
