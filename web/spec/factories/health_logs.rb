FactoryBot.define do
  factory :health_log do
    container
    lifecycle_id { SecureRandom.uuid }
  end
end
