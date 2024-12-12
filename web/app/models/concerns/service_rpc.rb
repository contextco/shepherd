# frozen_string_literal: true

module ServiceRPC
  extend ActiveSupport::Concern

  def rpc_service
    Sidecar::ServiceParams.new(
      name:,
      replica_count: 1,
      image: rpc_image,
      resources: rpc_resources,
      environment_config: rpc_environment_config,
      endpoints: rpc_endpoints,
      init_config: rpc_init_configs,
      persistent_volume_claims: rpc_persistent_volume_claims,
      ingress_config: rpc_ingress_config
    )
  end

  private

  def rpc_ingress_config
    return nil if ingress_port.nil?

    Sidecar::IngressParams.new(
      port: ingress_port,
      preference: Sidecar::IngressPreference::PREFER_INTERNAL,
    )
  end

  def rpc_resources
    Sidecar::Resources.new(
      cpu_cores_requested: cpu_cores,
      cpu_cores_limit: cpu_cores,
      memory_bytes_requested: memory_bytes,
      memory_bytes_limit: memory_bytes
      )
  end

  def rpc_image
    Sidecar::Image.new(
      name: image_without_tag,
      tag: image_tag,
      credential: rpc_image_credential
    )
  end

  def rpc_image_credential
    return nil if image_username.blank? || image_password.blank?

    Sidecar::ImageCredentials.new(
      username: image_username,
      password: image_password
    )
  end

  def rpc_endpoints
    ports.map(&:to_i).map { |port| Sidecar::Endpoint.new(port:) }
  end

  def rpc_environment_config
    env_vars = environment_variables.map do |env_var|
      Sidecar::EnvironmentVariable.new(
        name: env_var["name"],
        value: env_var["value"]
      )
    end

    secret_vars = secrets.map do |secret|
      Sidecar::Secret.new(
        name: secret.k8s_name,
        environment_key: secret.environment_key
      )
    end

    Sidecar::EnvironmentConfig.new(environment_variables: env_vars, secrets: secret_vars)
  end

  def rpc_init_configs
    Sidecar::InitConfig.new(init_commands: [ predeploy_command ]) if predeploy_command.present?
  end

  def rpc_persistent_volume_claims
    return nil if pvc_size_bytes.nil?

    [
      Sidecar::PersistentVolumeClaimParams.new(
        name: pvc_name,
        size_bytes: pvc_size_bytes,
        path: pvc_mount_path
      )
    ]
  end
end
