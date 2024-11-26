# frozen_string_literal: true

class Chart::Publisher
  class ChartValidationError < StandardError; end

  def initialize(rpc_chart, helm_repos)
    @client = SidecarClient.client
    @rpc_chart = rpc_chart
    @helm_repos = helm_repos
  end

  def validate_chart!
    req = Sidecar::ValidateChartRequest.new(chart: @rpc_chart)
    resp = @client.send(:validate_chart, req)

    errors = resp.errors.map { |error| "SideCar Validation Error: #{error}" }.join("\n")
    Rails.logger.info(errors) unless resp.valid

    raise Chart::Publisher::ChartValidationError, errors unless resp.valid
  end

  def publish_chart!
    repository_directories.each do |repository_directory|
      req = Sidecar::PublishChartRequest.new(chart: @rpc_chart, repository_directory:)
      @client.send(:publish_chart, req)
    end
  end

  private

  def repository_directories
    @repository_directories ||= @helm_repos.map(&:repo_name)
  end
end
