require "rails_helper"

RSpec.describe WebhookDelivery, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:webhook_endpoint) }
    it { is_expected.to belong_to(:tracking_event) }
  end

  describe "enum status" do
    it "defines the expected status values" do
      expect(described_class.statuses).to eq(
        "pending" => 0,
        "success" => 1,
        "failed" => 2
      )
    end
  end

  describe "response_body truncation" do
    it "truncates response_body to 1024 bytes" do
      long_body = "x" * 2000
      delivery = build(:webhook_delivery, response_body: long_body)
      delivery.valid?
      expect(delivery.response_body.bytesize).to eq(1024)
    end

    it "leaves short response_body unchanged" do
      delivery = build(:webhook_delivery, response_body: "short")
      delivery.valid?
      expect(delivery.response_body).to eq("short")
    end

    it "handles nil response_body" do
      delivery = build(:webhook_delivery, response_body: nil)
      delivery.valid?
      expect(delivery.response_body).to be_nil
    end
  end
end
