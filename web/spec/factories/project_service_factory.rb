FactoryBot.define do
  factory :project_service do
    name { 'generic-service' }
    image { 'generic-service:12.4.3' }
    environment_variables { { 'key' => 'value' } }
    secrets { [ 'my-secret' ] }
    resources { { "cpu_limit": "35", "cpu_request": "25", "memory_limit": "55", "cpu_limit_unit": "Cores", "memory_request": "45", "cpu_request_unit": "Cores", "memory_limit_unit": "Mi", "cpu_limit_combined": "35Cores", "memory_request_unit": "Gi", "cpu_request_combined": "25Cores", "memory_limit_combined": "55Mi", "memory_request_combined": "45Gi" } }
  end
end
