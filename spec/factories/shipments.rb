FactoryBot.define do
  factory :shipment do
    sequence(:reference_number) { |n| "REF-#{n.to_s.rjust(6, '0')}" }
    origin { "New York, NY" }
    destination { "Los Angeles, CA" }
    carrier { "FedEx" }
    status { :pending }
  end
end
