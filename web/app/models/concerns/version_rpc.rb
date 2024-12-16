# frozen_string_literal: true

module VersionRPC
  extend ActiveSupport::Concern

  def rpc_chart(project_subscriber:)
    services_params = rpc_services
    services_params << agent_rpc_service(project_subscriber) if full_agent?

    Sidecar::ChartParams.new(
      name: project.name,
      version:,
      services: services_params,
      dependencies: rpc_dependencies
    )
  end

  private

  def rpc_services
    services.map(&:rpc_service)
  end

  def rpc_dependencies
    dependencies.map(&:rpc_dependency)
  end

  def agent_rpc_service(project_subscriber)
    Sidecar::ServiceParams.new(
      name: "shepherd-agent",
      replica_count: 1,
      image: Sidecar::Image.new(
        name: "alecbarber/trust-shepherd",
        tag: "stable"
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
            value: project_subscriber.name
          ),
          Sidecar::EnvironmentVariable.new(
            name: "BEARER_TOKEN",
            value: project_subscriber.tokens.first.token
          ),
          Sidecar::EnvironmentVariable.new(
            name: "BACKEND_ADDR",
            value: "https://vpc-grpc-gateway.onrender.com"
          )
        ]
      )
    )
  end
end
