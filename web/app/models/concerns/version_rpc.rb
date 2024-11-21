# frozen_string_literal: true

module VersionRPC
  extend ActiveSupport::Concern

  def rpc_chart
    Sidecar::ChartParams.new(
      name: project.name,
      version:,
      services: rpc_services,
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
end
