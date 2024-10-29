FactoryBot.define do
  factory :event_log do
    container
    event_type { :heartbeat }
  end
end
