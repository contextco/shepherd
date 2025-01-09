# frozen_string_literal: true

class Chart::Publisher
  include AgentProto
  class ChartValidationError < StandardError; end

  def initialize(subscriber, helm_repos)
    @client = SidecarClient.client
    @subscriber = subscriber
    @helm_repos = helm_repos
  end

  def validate_chart!
    req = Sidecar::ValidateChartRequest.new(chart: rpc_chart)
    resp = @client.send(:validate_chart, req)

    errors = resp.errors.map { |error| "SideCar Validation Error: #{error}" }.join("\n")
    Rails.logger.info(errors) unless resp.valid

    raise Chart::Publisher::ChartValidationError, errors unless resp.valid
  end

  def publish_chart!
    repository_directories.each do |repository_directory|
      req = Sidecar::PublishChartRequest.new(chart: rpc_chart, repository_directory:)
      @client.send(:publish_chart, req)
    end
  end

  private

  attr_reader :subscriber
  delegate :project_version, to: :subscriber
  delegate :project, to: :project_version

  def rpc_chart
    services_params = rpc_services
    services_params << agent_proto_definition(subscriber) if project_version.full_agent?

    Sidecar::ChartParams.new(
      name: project.name,
      version: project_version.version,
      services: services_params,
      dependencies: rpc_dependencies
    )
  end

  def rpc_service(service)
    Sidecar::ServiceParams.new(
      name: service.name,
      replica_count: 1,
      image: rpc_image(service),
      resources: rpc_resources(service),
      environment_config: rpc_environment_config(service),
      endpoints: rpc_endpoints(service),
      init_config: rpc_init_configs(service),
      persistent_volume_claims: rpc_persistent_volume_claims(service),
      ingress_config: rpc_ingress_config(service)
    )
  end

  def rpc_ingress_config(service)
    return nil if service.ingress_port.nil?

    Sidecar::IngressParams.new(
      port: service.ingress_port,
      preference: Sidecar::IngressPreference::PREFER_INTERNAL,
      )
  end

  def rpc_resources(service)
    Sidecar::Resources.new(
      cpu_cores_requested: service.cpu_cores,
      cpu_cores_limit: service.cpu_cores,
      memory_bytes_requested: service.memory_bytes,
      memory_bytes_limit: service.memory_bytes
    )
  end

  def rpc_image(service)
    Sidecar::Image.new(
      name: service.image_without_tag,
      tag: service.image_tag,
      credential: rpc_image_credential(service),
      pull_policy: Sidecar::ImagePullPolicy::IMAGE_PULL_POLICY_IF_NOT_PRESENT
    )
  end

  def rpc_image_credential(service)
    return nil if service.image_username.blank? || service.image_password.blank?

    Sidecar::ImageCredentials.new(
      username: service.image_username,
      password: service.image_password
    )
  end

  def rpc_endpoints(service)
    service.ports.map(&:to_i).map { |port| Sidecar::Endpoint.new(port:) }
  end

  def rpc_environment_config(service)
    env_vars = service.environment_variables.map do |env_var|
      Sidecar::EnvironmentVariable.new(
        name: env_var["name"],
        value: env_var["value"]
      )
    end

    secret_vars = service.secrets.map do |secret|
      Sidecar::Secret.new(
        name: secret.k8s_name,
        environment_key: secret.environment_key
      )
    end

    Sidecar::EnvironmentConfig.new(environment_variables: env_vars, secrets: secret_vars)
  end

  def rpc_init_configs(service)
    Sidecar::InitConfig.new(init_commands: [ service.predeploy_command ]) if service.predeploy_command.present?
  end

  def rpc_persistent_volume_claims(service)
    return nil if service.pvc_size_bytes.nil?

    [
      Sidecar::PersistentVolumeClaimParams.new(
        name: service.pvc_name,
        size_bytes: service.pvc_size_bytes,
        path: service.pvc_mount_path
      )
    ]
  end


  def repository_directories
    @repository_directories ||= @helm_repos.map(&:repo_name)
  end

  def rpc_dependency(dependency)
    Sidecar::DependencyParams.new(
      name: dependency.chart_name,
      values_alias: dependency.name,
      version: dependency.version,
      repository_url: dependency.repo_url,
      overrides: rpc_overrides(dependency)
    )
  end


  def rpc_overrides(dependency)
    override_builder = dependency.info.override_builder.new(configs: dependency.configs)

    override_builder.create
  end


  def rpc_services
    project_version.services.map { |service| rpc_service(service) }
  end

  def rpc_dependencies
    project_version.dependencies.map { |dep| rpc_dependency(dep) }
  end
end
