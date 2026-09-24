require "rails_helper"

RSpec.describe "Api::V1::WebhookEndpoints", type: :request do
  let(:shipment) { create(:shipment) }

  describe "GET /api/v1/webhook_endpoints" do
    it "returns all endpoints ordered by created_at desc" do
      older = create(:webhook_endpoint, created_at: 1.day.ago)
      newer = create(:webhook_endpoint, created_at: Time.current)
      get "/api/v1/webhook_endpoints"
      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body).map { |e| e["id"] }
      expect(ids).to eq([newer.id, older.id])
    end

    it "returns an empty array when no endpoints exist" do
      get "/api/v1/webhook_endpoints"
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end
  end

  describe "GET /api/v1/webhook_endpoints/:id" do
    it "returns the endpoint" do
      endpoint = create(:webhook_endpoint, shipment: shipment)
      get "/api/v1/webhook_endpoints/#{endpoint.id}"
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["id"]).to eq(endpoint.id)
      expect(body["url"]).to eq(endpoint.url)
    end

    it "returns 404 for non-existent endpoint" do
      get "/api/v1/webhook_endpoints/999999"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/webhook_endpoints" do
    it "creates an endpoint with all fields" do
      post "/api/v1/webhook_endpoints", params: {
        webhook_endpoint: {
          url: "https://example.com/hook",
          secret: "my_secret",
          shipment_id: shipment.id,
          status_filters: ["delivered", "failed"],
          active: false
        }
      }
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["url"]).to eq("https://example.com/hook")
      expect(body["shipment_id"]).to eq(shipment.id)
      expect(body["status_filters"]).to eq(["delivered", "failed"])
      expect(body["active"]).to eq(false)
    end

    it "creates an endpoint with minimal fields and defaults" do
      post "/api/v1/webhook_endpoints", params: {
        webhook_endpoint: { url: "https://example.com/hook", secret: "s" }
      }
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["shipment_id"]).to be_nil
      expect(body["status_filters"]).to eq([])
      expect(body["active"]).to eq(true)
    end

    it "returns 422 when url is missing" do
      post "/api/v1/webhook_endpoints", params: {
        webhook_endpoint: { secret: "s" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
      errors = JSON.parse(response.body)["errors"]
      expect(errors["url"]).to be_present
    end

    it "returns 422 when secret is missing" do
      post "/api/v1/webhook_endpoints", params: {
        webhook_endpoint: { url: "https://example.com/hook" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
      errors = JSON.parse(response.body)["errors"]
      expect(errors["secret"]).to be_present
    end

    it "returns 422 when shipment_id references a non-existent shipment" do
      post "/api/v1/webhook_endpoints", params: {
        webhook_endpoint: { url: "https://example.com/hook", secret: "s", shipment_id: 999999 }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 when status_filters contains invalid values" do
      post "/api/v1/webhook_endpoints", params: {
        webhook_endpoint: {
          url: "https://example.com/hook",
          secret: "s",
          status_filters: ["invalid_status"]
        }
      }
      expect(response).to have_http_status(:unprocessable_entity)
      errors = JSON.parse(response.body)["errors"]
      expect(errors["status_filters"]).to be_present
    end
  end

  describe "PATCH /api/v1/webhook_endpoints/:id" do
    let!(:endpoint) { create(:webhook_endpoint) }

    it "updates the endpoint" do
      patch "/api/v1/webhook_endpoints/#{endpoint.id}", params: {
        webhook_endpoint: { url: "https://updated.com/hook", active: false }
      }
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["url"]).to eq("https://updated.com/hook")
      expect(body["active"]).to eq(false)
    end

    it "returns 422 for invalid update" do
      patch "/api/v1/webhook_endpoints/#{endpoint.id}", params: {
        webhook_endpoint: { status_filters: ["bogus"] }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /api/v1/webhook_endpoints/:id" do
    it "deletes the endpoint" do
      endpoint = create(:webhook_endpoint)
      expect {
        delete "/api/v1/webhook_endpoints/#{endpoint.id}"
      }.to change(WebhookEndpoint, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "returns 404 for non-existent endpoint" do
      delete "/api/v1/webhook_endpoints/999999"
      expect(response).to have_http_status(:not_found)
    end
  end
end
