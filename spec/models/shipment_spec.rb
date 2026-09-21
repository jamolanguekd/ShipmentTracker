require "rails_helper"

RSpec.describe Shipment, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:tracking_events).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:shipment) }

    it { is_expected.to validate_presence_of(:reference_number) }
    it { is_expected.to validate_uniqueness_of(:reference_number) }
    it { is_expected.to validate_presence_of(:origin) }
    it { is_expected.to validate_presence_of(:destination) }
  end

  describe "enum status" do
    it "defines the expected status values" do
      expect(Shipment.statuses).to eq(
        "pending" => 0,
        "in_transit" => 1,
        "out_for_delivery" => 2,
        "delivered" => 3,
        "failed" => 4
      )
    end

    it "defaults to pending" do
      shipment = build(:shipment)
      expect(shipment.status).to eq("pending")
    end
  end
end
