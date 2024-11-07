FactoryBot.define do
  factory :project do
    name { 'project-name' }
    team

    after(:create) do |project|
      create(:project_version, project:)
    end
  end
end
