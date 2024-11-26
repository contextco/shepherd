FactoryBot.define do
  factory :project_subscriber do
    name { FFaker::Lorem.word }
    project { create(:project) }
  end
end
