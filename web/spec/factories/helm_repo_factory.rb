FactoryBot.define do
  factory :helm_repo do
    name { FFaker::Lorem.word }
    project_subscriber
  end
end
