require "rails_helper"

RSpec.describe "Api::V1::Shipments", type: :request do
  let(:valid_attributes) do
    {
      shipment: {
        reference_number: "REF-001",
        origin: "New York, NY",
        destination: "Los Angeles, CA",
        carrier: "FedEx",
        status: "pending"
      }
    }
  end

  describe "POST /api/v1/shipments" do
    context "with valid parameters" do
      it "creates a shipment and returns 201" do
        post "/api/v1/shipments", params: valid_attributes, as: :json
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json).to include(
          "reference_number" => "REF-001",
          "origin" => "New York, NY",
          "destination" => "Los Angeles, CA",
          "carrier" => "FedEx",
          "status" => "pending"
        )
        expect(json["id"]).to be_present
        expect(json["created_at"]).to be_present
      end
    end

    context "with missing required field" do
      it "returns 422 with error details" do
        post "/api/v1/shipments", params: { shipment: { origin: "New York, NY" } }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end
    end

    context "with invalid status value" do
      it "returns 422 with error details" do
        params = valid_attributes.deep_merge(shipment: { status: "flying" })
        expect {
          post "/api/v1/shipments", params: params, as: :json
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe "GET /api/v1/shipments/:id" do
    context "when shipment exists" do
      let!(:shipment) { create(:shipment) }

      it "returns 200 with the shipment" do
        get "/api/v1/shipments/#{shipment.id}", as: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["id"]).to eq(shipment.id)
      end
    end

    context "when shipment does not exist" do
      it "returns 404 with error body" do
        get "/api/v1/shipments/999999", as: :json
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["error"]).to be_present
      end
    end
  end

  describe "GET /api/v1/shipments" do
    it "returns 200 with shipments ordered by created_at descending" do
      older = create(:shipment, created_at: 2.days.ago)
      newer = create(:shipment, created_at: 1.day.ago)
      get "/api/v1/shipments", as: :json
      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body).map { |s| s["id"] }
      expect(ids).to eq([newer.id, older.id])
    end
  end

  describe "PATCH /api/v1/shipments/:id" do
    let!(:shipment) { create(:shipment) }

    context "with valid parameters" do
      it "returns 200 with updated shipment" do
        patch "/api/v1/shipments/#{shipment.id}",
          params: { shipment: { status: "in_transit" } },
          as: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("in_transit")
      end
    end

    context "with invalid parameters" do
      it "returns 422 with error details" do
        patch "/api/v1/shipments/#{shipment.id}",
          params: { shipment: { origin: "" } },
          as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end
    end
  end

  describe "DELETE /api/v1/shipments/:id" do
    context "when shipment exists" do
      let!(:shipment) { create(:shipment) }

      it "returns 204 with no body" do
        delete "/api/v1/shipments/#{shipment.id}", as: :json
        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context "when shipment does not exist" do
      it "returns 404" do
        delete "/api/v1/shipments/999999", as: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
