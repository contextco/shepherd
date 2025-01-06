FactoryBot.define do
  factory :project_subscriber do
    name { FFaker::Lorem.word }
    project_version { create(:project_version) }
  end
end
