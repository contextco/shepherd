FactoryBot.define do
  factory :project_version do
    version { '1.0.0' }
    description { 'This is a description' }
    project
    state { :draft }
  end
end
