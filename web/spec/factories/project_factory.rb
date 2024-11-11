FactoryBot.define do
  factory :project do
    name { 'project-name' }
    team

    after(:create) do |project|
      create(:project_version, project:)
      create(:helm_repo, project:)
    end
  end
end
