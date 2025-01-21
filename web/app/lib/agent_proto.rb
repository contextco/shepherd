# frozen_string_literal: true

module AgentProto
  def agent_proto_definition
    Sidecar::ServiceParams.new(
      name: "shepherd-agent",
      replica_count: 1,
      persistent_volume_claims: [
        Sidecar::PersistentVolumeClaimParams.new(
          name: "pvc-shepherd-agent",
          size_bytes: 1.gigabyte,
          path: "/mnt/data"
        )
      ],
      image: Sidecar::Image.new(
        name: "ghcr.io/contextco/shepherd",
        tag: "master",
        pull_policy: Sidecar::ImagePullPolicy::IMAGE_PULL_POLICY_ALWAYS
      ),
      resources: Sidecar::Resources.new(
        cpu_cores_requested: 1,
        cpu_cores_limit: 1,
        memory_bytes_requested: 2.gigabytes,
        memory_bytes_limit: 2.gigabytes
      ),
      environment_config: Sidecar::EnvironmentConfig.new(
        meta_environment_fields_enabled: true,
        environment_variables: [
          # It would be really nice to encapsulate all of this into a single signed env var.
          # This would mean the interface is simpler (with only 1 var) and provides guarantees it hasn't been tampered
          # with by the client.
          Sidecar::EnvironmentVariable.new(
            name: "NAME",
            value: subscriber&.name || "unknown"
          ),
          Sidecar::EnvironmentVariable.new(
            name: "BEARER_TOKEN",
            value: subscriber&.tokens&.first&.token || "placeholder"
          ),
          Sidecar::EnvironmentVariable.new(
            name: "BACKEND_ADDR",
            value: ENV["SHEPHERD_AGENT_API_ENDPOINT"] || "https://agent.trustshepherd.com"
          ),
          Sidecar::EnvironmentVariable.new(
            name: "SHEPHERD_PROJECT_VERSION_ID",
            value: project_version.id.to_s
          )
        ]
      )
    )
  end
end
