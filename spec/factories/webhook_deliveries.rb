FactoryBot.define do
  factory :webhook_delivery do
    association :webhook_endpoint
    association :tracking_event
    payload { { event: "tracking_event.created", data: {} } }
    status { :pending }
    attempts { 0 }
  end
end
