# Spec Delta

## Purpose

Provides CRUD management of shipment records, including creation, retrieval, listing, updating, and deletion via a JSON REST API.

## ADDED Requirements

### Requirement: Create a shipment
The system SHALL accept a POST request with shipment attributes and persist a new shipment record, returning its full representation with a unique identifier.

#### Scenario: Successful creation
- **WHEN** a client POSTs valid shipment attributes to `/api/v1/shipments`
- **THEN** the system responds with HTTP 201 and the created shipment record including its `id`, `reference_number`, `origin`, `destination`, `carrier`, `status`, and timestamps

#### Scenario: Missing required field
- **WHEN** a client POSTs a payload missing a required attribute (e.g., `origin`)
- **THEN** the system responds with HTTP 422 and a JSON error object describing the missing field

### Requirement: Retrieve a shipment
The system SHALL return a single shipment record by its unique identifier.

#### Scenario: Shipment found
- **WHEN** a client sends GET `/api/v1/shipments/:id` for an existing record
- **THEN** the system responds with HTTP 200 and the full shipment JSON representation

#### Scenario: Shipment not found
- **WHEN** a client sends GET `/api/v1/shipments/:id` for a non-existent record
- **THEN** the system responds with HTTP 404 and a JSON error body

### Requirement: List shipments
The system SHALL return a paginated list of all shipment records.

#### Scenario: Default listing
- **WHEN** a client sends GET `/api/v1/shipments`
- **THEN** the system responds with HTTP 200 and an array of shipment records ordered by creation date descending

### Requirement: Update a shipment
The system SHALL allow partial or full update of a shipment record's mutable attributes.

#### Scenario: Successful update
- **WHEN** a client sends PATCH `/api/v1/shipments/:id` with valid attributes
- **THEN** the system responds with HTTP 200 and the updated shipment record

#### Scenario: Invalid update
- **WHEN** a client sends PATCH `/api/v1/shipments/:id` with an attribute that fails validation
- **THEN** the system responds with HTTP 422 and a JSON error object

### Requirement: Delete a shipment
The system SHALL remove a shipment record permanently when a DELETE request is received.

#### Scenario: Successful deletion
- **WHEN** a client sends DELETE `/api/v1/shipments/:id` for an existing record
- **THEN** the system responds with HTTP 204 and no body

#### Scenario: Delete non-existent shipment
- **WHEN** a client sends DELETE `/api/v1/shipments/:id` for a record that does not exist
- **THEN** the system responds with HTTP 404

### Requirement: Shipment status field
The system SHALL constrain the `status` field to a defined set of values: `pending`, `in_transit`, `out_for_delivery`, `delivered`, `failed`.

#### Scenario: Invalid status value
- **WHEN** a client creates or updates a shipment with a `status` value outside the allowed set
- **THEN** the system responds with HTTP 422 and an error describing the invalid value
