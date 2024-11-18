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
      endpoints: rpc_endpoints
    )
  end

  private

  def rpc_resources
    Sidecar::Resources.new(
      cpu_cores_requested: cpu_cores,
      cpu_cores_limit: cpu_cores,
      memory_bytes_requested: memory_bytes,
      memory_bytes_limit: memory_bytes
      )
  end

  def rpc_image
    Sidecar::Image.new(name: image_without_tag, tag: image_tag)
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
      name = env_to_k8s_secret_name(secret)
      Sidecar::Secret.new(
        name:,
        environment_key: secret
      )
    end

    Sidecar::EnvironmentConfig.new(environment_variables: env_vars, secrets: secret_vars)
  end

  def env_to_k8s_secret_name(env_name)
    raise ArgumentError, "Env variable cannot be empty" if env_name.blank?

    # Convert to lowercase and replace invalid characters
    secret_name = env_name.to_s.downcase
                          .gsub(/[^a-z0-9.\-]/, "-")  # Replace invalid chars with hyphen
                          .gsub(/[-.]{2,}/, "-")      # Replace multiple dots/hyphens with single hyphen

    # Ensure it starts and ends with alphanumeric
    secret_name = "x#{secret_name}" if secret_name.match?(/^[^a-z0-9]/)
    secret_name = "#{secret_name}x" if secret_name.match?(/[^a-z0-9]$/)

    # Truncate to maximum length while preserving valid ending
    if secret_name.length > 253
      secret_name = secret_name[0...252]
      secret_name = secret_name.sub(/[^a-z0-9]$/, "x")
    end

    secret_name
  end
end
