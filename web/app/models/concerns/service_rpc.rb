# frozen_string_literal: true

module ServiceRPC
  extend ActiveSupport::Concern

  def validate_chart
    client = SidecarClient.client
    req = ValidateChartRequest.new(chart: rpc_chart)
    resp = client.validate_chart(req)

    errors = resp.errors.map { |error| "SideCar Validation Error: #{error}" }.join("\n")
    Rails.logger.info(errors) unless resp.valid

    resp.valid
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
end
