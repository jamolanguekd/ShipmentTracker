# Proposal

## Why

A shipment tracker API is needed to manage and expose the lifecycle of shipments — from creation through delivery — via a structured REST interface. Building it now establishes the core domain and data layer that downstream consumers (mobile apps, internal tools, third-party integrations) can depend on.

## What Changes

- New Rails 6.1 API-only application (Ruby 3.1.6) with no view layer
- RESTful JSON endpoints for creating, reading, updating, and listing shipments
- RESTful JSON endpoints for recording and querying shipment status events (tracking history)
- RSpec-based unit and request test suite
- Dockerized application with a dedicated PostgreSQL container, using Docker Compose for local development and CI parity
- `.ruby-version` pinned to 3.1.6

## Capabilities

### New Capabilities

- `shipments`: CRUD management of shipment records (origin, destination, carrier, reference number, current status)
- `shipment-tracking`: Append-only log of status events for a shipment (status code, location, timestamp, notes); supports querying the full event history for a given shipment

### Modified Capabilities

<!-- None — greenfield project with no existing specs -->

## Impact

- Introduces the Rails application itself (Gemfile, config/, db/schema, app/models, app/controllers, app/serializers)
- Introduces `docker-compose.yml`, `Dockerfile`, and `.env.example` for containerized local development
- PostgreSQL is the only supported database; connection string is environment-variable driven
- No authentication or authorization in scope for this change
- No background jobs or mailers in scope for this change
