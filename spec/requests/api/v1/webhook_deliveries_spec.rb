require "rails_helper"

RSpec.describe "Api::V1::WebhookDeliveries", type: :request do
  let(:endpoint) { create(:webhook_endpoint) }

  describe "GET /api/v1/webhook_endpoints/:webhook_endpoint_id/deliveries" do
    it "returns deliveries for the endpoint ordered by created_at desc" do
      older = create(:webhook_delivery, webhook_endpoint: endpoint, created_at: 1.day.ago)
      newer = create(:webhook_delivery, webhook_endpoint: endpoint, created_at: Time.current)
      get "/api/v1/webhook_endpoints/#{endpoint.id}/deliveries"
      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body).map { |d| d["id"] }
      expect(ids).to eq([newer.id, older.id])
    end

    it "returns an empty array when no deliveries exist" do
      get "/api/v1/webhook_endpoints/#{endpoint.id}/deliveries"
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns 404 for non-existent endpoint" do
      get "/api/v1/webhook_endpoints/999999/deliveries"
      expect(response).to have_http_status(:not_found)
    end
  end
end
