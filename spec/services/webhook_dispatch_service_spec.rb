require "rails_helper"

RSpec.describe WebhookDispatchService do
  let(:shipment) { create(:shipment) }
  let(:tracking_event) { create(:tracking_event, shipment: shipment, status: :delivered) }

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  describe ".call" do
    it "creates a delivery and enqueues a job for a matching scoped endpoint" do
      endpoint = create(:webhook_endpoint, shipment: shipment, status_filters: ["delivered"])
      expect {
        described_class.call(tracking_event)
      }.to change(WebhookDelivery, :count).by(1)
        .and have_enqueued_job(WebhookDeliveryJob)
      delivery = WebhookDelivery.last
      expect(delivery.webhook_endpoint).to eq(endpoint)
      expect(delivery.tracking_event).to eq(tracking_event)
      expect(delivery.pending?).to be true
    end

    it "matches a wildcard endpoint (nil shipment_id, empty status_filters)" do
      endpoint = create(:webhook_endpoint, shipment: nil, status_filters: [])
      expect {
        described_class.call(tracking_event)
      }.to change(WebhookDelivery, :count).by(1)
      expect(WebhookDelivery.last.webhook_endpoint).to eq(endpoint)
    end

    it "matches an endpoint with nil shipment_id and matching status filter" do
      endpoint = create(:webhook_endpoint, shipment: nil, status_filters: ["delivered", "failed"])
      described_class.call(tracking_event)
      expect(WebhookDelivery.last.webhook_endpoint).to eq(endpoint)
    end

    it "skips an endpoint with non-matching status filter" do
      create(:webhook_endpoint, shipment: shipment, status_filters: ["in_transit"])
      expect {
        described_class.call(tracking_event)
      }.not_to change(WebhookDelivery, :count)
    end

    it "skips inactive endpoints" do
      create(:webhook_endpoint, shipment: shipment, status_filters: [], active: false)
      expect {
        described_class.call(tracking_event)
      }.not_to change(WebhookDelivery, :count)
    end

    it "skips endpoints scoped to a different shipment" do
      other_shipment = create(:shipment)
      create(:webhook_endpoint, shipment: other_shipment, status_filters: [])
      expect {
        described_class.call(tracking_event)
      }.not_to change(WebhookDelivery, :count)
    end

    it "creates deliveries for multiple matching endpoints" do
      create(:webhook_endpoint, shipment: nil, status_filters: [])
      create(:webhook_endpoint, shipment: shipment, status_filters: ["delivered"])
      expect {
        described_class.call(tracking_event)
      }.to change(WebhookDelivery, :count).by(2)
    end

    it "enqueues a WebhookDeliveryJob for each delivery" do
      create(:webhook_endpoint, shipment: nil, status_filters: [])
      create(:webhook_endpoint, shipment: shipment, status_filters: [])
      described_class.call(tracking_event)
      expect(WebhookDeliveryJob).to have_been_enqueued.exactly(2).times
    end

    it "builds the correct payload structure" do
      create(:webhook_endpoint, shipment: nil, status_filters: [])
      described_class.call(tracking_event)
      payload = WebhookDelivery.last.payload
      expect(payload["event"]).to eq("tracking_event.created")
      expect(payload["data"]["tracking_event"]["id"]).to eq(tracking_event.id)
      expect(payload["data"]["shipment"]["id"]).to eq(shipment.id)
      expect(payload["data"]["shipment"]["reference_number"]).to eq(shipment.reference_number)
    end
  end
end
