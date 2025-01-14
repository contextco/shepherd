FactoryBot.define do
  factory :project_subscriber do
    name { FFaker::Lorem.word }
    project_version { association :project_version, **{ team: team }.compact_blank }

    transient do
      team { nil }
    end
  end
end
