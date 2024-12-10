# frozen_string_literal: true

module Chart::Dependency::Data
  DATA = [
    {
      name: "postgresql",
      human_visible_name: "PostgreSQL",
      description: "A popular and powerful open-source relational database management system.",
      icon: "circle-stack",
      version: "16.x.x",
      variants: [
        {
          version: "15.10.0",
          human_visible_version: "15"
        },
        {
          version: "16.6.0",
          human_visible_version: "16"
        },
        {
          version: "17.2.0",
          human_visible_version: "17"
        }
      ],
      repository: "oci://registry-1.docker.io/bitnamicharts",
      chart_name: "postgresql",
      form_component: Dependencies::PostgresqlComponent,
      form: Dependencies::PostgresqlForm,
      override_builder: Chart::Override::Postgresql
    },
    {
      name: "redis",
      icon: "square-3-stack-3d",
      version: "20.x.x",
      variants: [
        {
          version: "7.4.1",
          human_visible_version: "7"
        }
      ],
      repository: "oci://registry-1.docker.io/bitnamicharts",
      chart_name: "redis",
      description: "An open-source, in-memory key-value store, useful for caching or as a lightweight database.",
      form_component: Dependencies::RedisComponent,
      form: Dependencies::RedisForm,
      override_builder: Chart::Override::Redis
    }
  ]
end
