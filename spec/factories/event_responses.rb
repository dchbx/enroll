FactoryGirl.define do
  factory :event_response do
    received_at DateTime.now - 1.day
  end
end