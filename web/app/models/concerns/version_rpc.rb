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
    services.map do |service|
      service.rpc_service
    end
  end

  def rpc_dependencies
    dependencies.map do |dependency|
      dependency.rpc_dependency
    end
  end
end
