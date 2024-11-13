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
      version: "0.0.1",
      image: rpc_image,
      environment_config: rpc_environment_config,
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

    EnvironmentConfig.new(environment_variables: env_vars)
  end

  def rpc_client
    @rpc_client ||= SidecarClient.client
  end
end
