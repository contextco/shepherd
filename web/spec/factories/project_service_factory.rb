FactoryBot.define do
  factory :project_service do
    name { 'generic-service' }
    image { 'generic-service:12.4.3' }
    environment_variables { [ { name: 'key', value: 'value' } ] }
    secrets { [ 'my-secret' ] }
    cpu_cores { 1 }
    memory_bytes { 2.gigabytes }
    pvc_size_bytes { nil }
    pvc_mount_path { nil }
    pvc_name { 'standard-pvc-name' }
    ports { [ 80 ] }

    transient do
      team { nil }
    end

    project_version { association :project_version, **{ team: team }.compact_blank }
  end

  factory :nginx_service, class: 'ProjectService' do
    name { 'nginx' }
    image { 'nginx:1.26-alpine' }
    cpu_cores { 1 }
    memory_bytes { 2.gigabytes }
  end
end
