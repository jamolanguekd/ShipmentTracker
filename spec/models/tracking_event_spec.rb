require "rails_helper"

RSpec.describe TrackingEvent, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:shipment) }
  end

  describe "validations" do
    subject { build(:tracking_event) }

    it { is_expected.to validate_presence_of(:occurred_at) }
  end

  describe "enum status" do
    it "defines the expected status values" do
      expect(TrackingEvent.statuses).to eq(
        "pending" => 0,
        "in_transit" => 1,
        "out_for_delivery" => 2,
        "delivered" => 3,
        "failed" => 4
      )
    end
  end
end
