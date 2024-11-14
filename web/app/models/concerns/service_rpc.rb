# frozen_string_literal: true

module ServiceRPC
  extend ActiveSupport::Concern

  def validate_chart
    req = ValidateChartRequest.new(chart: rpc_chart)
    resp = rpc_client.validate_chart(req)

    errors = resp.errors.map { |error| "SideCar Validation Error: #{error}" }.join("\n")
    Rails.logger.info(errors) unless resp.valid

    resp.valid
  end

  def publish_chart!
    # this only lives here ftm. Eventually the project_version will handle all publishing
    repository_directory = helm_repo.name
    req = PublishChartRequest.new(chart: rpc_chart, repository_directory:)
    rpc_client.publish_chart(req)
  end

  private

  def rpc_chart
    ChartParams.new(
      name: name,
      version: project_version.version,
      replica_count: 1,
      image: rpc_image,
      resources: rpc_resources,
      environment_config: rpc_environment_config,
      )
  end

  def rpc_resources
    Resources.new(
      cpu_cores_requested: cpu_cores,
      cpu_cores_limit: cpu_cores,
      memory_bytes_requested: memory_bytes,
      memory_bytes_limit: memory_bytes
      )
  end

  def rpc_image
    Image.new(name: image_without_tag, tag: image_tag)
  end

  def rpc_environment_config
    env_vars = environment_variables.map do |env_var|
      EnvironmentVariable.new(
        name: env_var["name"],
        value: env_var["value"]
      )
    end

    secret_vars = secrets.map do |secret|
      name = env_to_k8s_secret_name(secret)
      Secret.new(
        name:,
        environment_key: secret
      )
    end

    EnvironmentConfig.new(environment_variables: env_vars, secrets: secret_vars)
  end

  def rpc_client
    @rpc_client ||= SidecarClient.client
  end

  def env_to_k8s_secret_name(env_name)
    # Convert to lowercase and replace invalid characters
    secret_name = env_name.to_s.downcase
                          .gsub(/[^a-z0-9.\-]/, "-")  # Replace invalid chars with hyphen
                          .gsub(/^\W+|\W+$/, "")      # Remove leading/trailing non-word chars
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
