FactoryBot.define do
  factory :project_service do
    name { 'generic-service' }
    image { 'generic-service:12.4.3' }
    environment_variables { [ { name: 'key', value: 'value' } ] }
    secrets { [ 'my-secret' ] }
    cpu_cores { 1 }
    memory_bytes { 2.gigabytes }

    transient do
      team { nil }
    end

    project_version { association :project_version, **{ team: team }.compact_blank }
  end
end
