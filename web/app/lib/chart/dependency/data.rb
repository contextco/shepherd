# frozen_string_literal: true

module Chart::Dependency::Data
  DATA = [
    {
      name: "postgresql",
      human_visible_name: "PostgreSQL",
      description: "A popular and powerful open-source relational database management system.",
      icon: "circle-stack",
      variants: [
        {
          version: "15.x.x",
          human_visible_version: "15"
        },
        {
          version: "16.x.x",
          human_visible_version: "16"
        },
        {
          version: "17.x.x",
          human_visible_version: "17"
        }
      ],
      repository: "oci://registry-1.docker.io/bitnamicharts/postgresql",
      form_component: Dependencies::PostgresqlComponent
    },
    {
      name: "redis",
      icon: "square-3-stack-3d",
      variants: [
        {
          version: "20.x.x",
          human_visible_version: "20"
        }
      ],
      repository: "oci://registry-1.docker.io/bitnamicharts/redis",
      description: "An open-source, in-memory key-value store, useful for caching or as a lightweight database.",
      form_component: Dependencies::RedisComponent
    }

  ]
end
