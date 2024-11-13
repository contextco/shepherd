FactoryBot.define do
  factory :project_version do
    version { 3.times.map { rand(100) }.join('.') }
    description { 'This is a description' }
    state { :draft }

    transient do
      team { nil }
    end

    project { association :project, **{ team: team }.compact_blank }
  end
end
