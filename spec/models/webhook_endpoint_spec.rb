require "rails_helper"

RSpec.describe WebhookEndpoint, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:shipment).optional }
    it { is_expected.to have_many(:webhook_deliveries).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_presence_of(:secret) }

    describe "status_filters" do
      it "allows valid status values" do
        endpoint = build(:webhook_endpoint, status_filters: ["pending", "delivered"])
        expect(endpoint).to be_valid
      end

      it "allows empty status_filters" do
        endpoint = build(:webhook_endpoint, status_filters: [])
        expect(endpoint).to be_valid
      end

      it "rejects invalid status values" do
        endpoint = build(:webhook_endpoint, status_filters: ["invalid_status"])
        expect(endpoint).not_to be_valid
        expect(endpoint.errors[:status_filters]).to include("contains invalid values: invalid_status")
      end

      it "rejects a mix of valid and invalid values" do
        endpoint = build(:webhook_endpoint, status_filters: ["pending", "bogus"])
        expect(endpoint).not_to be_valid
        expect(endpoint.errors[:status_filters]).to include("contains invalid values: bogus")
      end
    end

    describe "shipment_id foreign key" do
      it "accepts a valid shipment" do
        shipment = create(:shipment)
        endpoint = build(:webhook_endpoint, shipment: shipment)
        expect(endpoint).to be_valid
      end

      it "accepts nil shipment (wildcard)" do
        endpoint = build(:webhook_endpoint, shipment: nil)
        expect(endpoint).to be_valid
      end
    end
  end

  describe "scopes" do
    describe ".active" do
      it "returns only active endpoints" do
        active = create(:webhook_endpoint, active: true)
        create(:webhook_endpoint, active: false)
        expect(described_class.active).to eq([active])
      end
    end
  end
end
