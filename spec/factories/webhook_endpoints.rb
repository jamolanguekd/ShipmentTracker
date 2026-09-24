FactoryBot.define do
  factory :webhook_endpoint do
    sequence(:url) { |n| "https://example.com/webhooks/#{n}" }
    secret { "test_secret_key" }
    shipment { nil }
    status_filters { [] }
    active { true }
  end
end
