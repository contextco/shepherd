# frozen_string_literal: true

class ChartPublisher
  class ChartValidationError < StandardError; end

  def initialize(rpc_chart, project_version)
    @client = SidecarClient.client
    @rpc_chart = rpc_chart
    @project_version = project_version
  end

  def validate_chart!
    req = Sidecar::ValidateChartRequest.new(chart: @rpc_chart)
    resp = @client.send(:validate_chart, req)

    errors = resp.errors.map { |error| "SideCar Validation Error: #{error}" }.join("\n")
    Rails.logger.info(errors) unless resp.valid

    raise ChartPublisher::ChartValidationError, errors unless resp.valid
  end

  def publish_chart!
    req = Sidecar::PublishChartRequest.new(chart: @rpc_chart, repository_directory:)
    @client.send(:publish_chart, req)
  end

  private

  def repository_directory
    @repository_directory ||= @project_version.helm_repo.name
  end
end
