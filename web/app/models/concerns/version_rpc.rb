# frozen_string_literal: true

module VersionRPC
  extend ActiveSupport::Concern

  def rpc_chart
    Sidecar::ChartParams.new(
      name: project.name,
      version:,
      services: rpc_services
    )
  end

  private

  def rpc_services
    services.map do |service|
      service.rpc_service
    end
  end
end
