FactoryBot.define do
  factory :tracking_event do
    association :shipment
    status { :pending }
    location { "Chicago, IL" }
    occurred_at { Time.current }
    notes { nil }
  end
end
