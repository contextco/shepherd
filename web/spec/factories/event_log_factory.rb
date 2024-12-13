FactoryBot.define do
  factory :event_log do
    agent_instance
    event_type { :heartbeat }
  end
end
