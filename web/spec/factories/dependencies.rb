FactoryBot.define do
  factory :dependency do
    name { "redis" }
    chart_name { "bitnamicharts/redis" }
    version { "20.x.x" }
    repo_url { "oci://registry-1.docker.io" }
    project_version
    configs { { cpu_cores: 4, disk_bytes: "5Gi", memory_bytes: 4294967296, app_version: "7.x.x", max_memory_policy: "volatile-lru", db_password: 'password' } }
  end
end
