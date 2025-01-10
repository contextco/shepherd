FactoryBot.define do
  factory :agent_instance do
    association(:subscriber, factory: :project_subscriber)
    name { "MyString" }
    lifecycle_id { "MyString" }
  end
end
