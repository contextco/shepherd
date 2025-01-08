# frozen_string_literal: true

module AgentProto
  def agent_proto_definition(subscriber)
    Sidecar::ServiceParams.new(
      name: "shepherd-agent",
      replica_count: 1,
      image: Sidecar::Image.new(
        name: "ghcr.io/contextco/onprem",
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
        environment_variables: [
          Sidecar::EnvironmentVariable.new(
            name: "NAME",
            value: subscriber.name
          ),
          Sidecar::EnvironmentVariable.new(
            name: "BEARER_TOKEN",
            value: subscriber.tokens.first.token
          ),
          Sidecar::EnvironmentVariable.new(
            name: "BACKEND_ADDR",
            value: ENV["SHEPHERD_AGENT_API_ENDPOINT"] || "https://agent.trustshepherd.com"
          )
        ]
      )
    )
  end
end
