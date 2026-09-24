class WebhookDispatchService
  def self.call(tracking_event)
    new(tracking_event).call
  end

  def initialize(tracking_event)
    @tracking_event = tracking_event
    @shipment = tracking_event.shipment
  end

  def call
    matching_endpoints.each do |endpoint|
      delivery = endpoint.webhook_deliveries.create!(
        tracking_event: @tracking_event,
        payload: build_payload,
        status: :pending,
        attempts: 0
      )
      WebhookDeliveryJob.perform_later(delivery.id)
    end
  end

  private

  def matching_endpoints
    endpoints = WebhookEndpoint.active
      .where(shipment_id: [nil, @shipment.id])

    endpoints.select do |endpoint|
      endpoint.status_filters.empty? || endpoint.status_filters.include?(@tracking_event.status)
    end
  end

  def build_payload
    {
      event: "tracking_event.created",
      delivered_at: Time.current.iso8601,
      data: {
        tracking_event: {
          id: @tracking_event.id,
          shipment_id: @tracking_event.shipment_id,
          status: @tracking_event.status,
          location: @tracking_event.location,
          occurred_at: @tracking_event.occurred_at.iso8601,
          notes: @tracking_event.notes,
          created_at: @tracking_event.created_at.iso8601
        },
        shipment: {
          id: @shipment.id,
          reference_number: @shipment.reference_number,
          origin: @shipment.origin,
          destination: @shipment.destination,
          carrier: @shipment.carrier,
          status: @shipment.status
        }
      }
    }
  end
end
