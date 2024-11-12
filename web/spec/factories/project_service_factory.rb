FactoryBot.define do
  factory :project_service do
    name { 'generic-service' }
    image { 'generic-service:12.4.3' }
    environment_variables { { 'key' => 'value' } }
    secrets { [ 'my-secret' ] }
    cpu_cores { 1 }
    memory_bytes { 2.gigabytes }
  end
end
