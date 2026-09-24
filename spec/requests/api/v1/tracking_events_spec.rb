require "rails_helper"

RSpec.describe "Api::V1::TrackingEvents", type: :request do
  let!(:shipment) { create(:shipment) }

  let(:valid_attributes) do
    {
      tracking_event: {
        status: "in_transit",
        location: "Chicago, IL",
        occurred_at: Time.current.iso8601,
        notes: "Package picked up"
      }
    }
  end

  describe "POST /api/v1/shipments/:shipment_id/tracking_events" do
    context "with valid parameters" do
      it "creates a tracking event and returns 201" do
        post "/api/v1/shipments/#{shipment.id}/tracking_events",
          params: valid_attributes,
          as: :json
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json).to include(
          "shipment_id" => shipment.id,
          "status" => "in_transit",
          "location" => "Chicago, IL"
        )
        expect(json["id"]).to be_present
        expect(json["occurred_at"]).to be_present
      end
    end

    context "when shipment does not exist" do
      it "returns 404" do
        post "/api/v1/shipments/999999/tracking_events",
          params: valid_attributes,
          as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with missing required field" do
      it "returns 422 when status is missing" do
        post "/api/v1/shipments/#{shipment.id}/tracking_events",
          params: { tracking_event: { location: "Chicago, IL", occurred_at: Time.current.iso8601 } },
          as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end

      it "returns 422 when occurred_at is missing" do
        post "/api/v1/shipments/#{shipment.id}/tracking_events",
          params: { tracking_event: { status: "in_transit", location: "Chicago, IL" } },
          as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end
    end

    context "webhook dispatch" do
      before { ActiveJob::Base.queue_adapter = :test }

      it "dispatches webhooks to matching endpoints" do
        create(:webhook_endpoint, shipment: shipment, status_filters: ["in_transit"])
        expect {
          post "/api/v1/shipments/#{shipment.id}/tracking_events",
            params: valid_attributes,
            as: :json
        }.to change(WebhookDelivery, :count).by(1)
          .and have_enqueued_job(WebhookDeliveryJob)
      end

      it "does not dispatch webhooks when no endpoints match" do
        create(:webhook_endpoint, shipment: shipment, status_filters: ["failed"])
        expect {
          post "/api/v1/shipments/#{shipment.id}/tracking_events",
            params: valid_attributes,
            as: :json
        }.not_to change(WebhookDelivery, :count)
      end

      it "does not dispatch webhooks on validation failure" do
        create(:webhook_endpoint, shipment: shipment, status_filters: [])
        expect {
          post "/api/v1/shipments/#{shipment.id}/tracking_events",
            params: { tracking_event: { location: "Chicago, IL" } },
            as: :json
        }.not_to change(WebhookDelivery, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /api/v1/shipments/:shipment_id/tracking_events" do
    context "with events" do
      it "returns events ordered by occurred_at ascending" do
        later_event = create(:tracking_event, shipment: shipment, occurred_at: 1.hour.from_now)
        earlier_event = create(:tracking_event, shipment: shipment, occurred_at: 1.hour.ago)
        get "/api/v1/shipments/#{shipment.id}/tracking_events", as: :json
        expect(response).to have_http_status(:ok)
        ids = JSON.parse(response.body).map { |e| e["id"] }
        expect(ids).to eq([earlier_event.id, later_event.id])
      end
    end

    context "with no events" do
      it "returns 200 with empty array" do
        get "/api/v1/shipments/#{shipment.id}/tracking_events", as: :json
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
    end

    context "when shipment does not exist" do
      it "returns 404" do
        get "/api/v1/shipments/999999/tracking_events", as: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /api/v1/shipments/:shipment_id/tracking_events/:id (immutability)" do
    let!(:event) { create(:tracking_event, shipment: shipment) }

    it "raises RoutingError because the route does not exist" do
      expect {
        patch "/api/v1/shipments/#{shipment.id}/tracking_events/#{event.id}",
          params: { tracking_event: { location: "Denver, CO" } },
          as: :json
      }.to raise_error(ActionController::RoutingError)
    end
  end

  describe "PUT /api/v1/shipments/:shipment_id/tracking_events/:id (immutability)" do
    let!(:event) { create(:tracking_event, shipment: shipment) }

    it "raises RoutingError because the route does not exist" do
      expect {
        put "/api/v1/shipments/#{shipment.id}/tracking_events/#{event.id}",
          params: { tracking_event: { location: "Denver, CO" } },
          as: :json
      }.to raise_error(ActionController::RoutingError)
    end
  end
end
