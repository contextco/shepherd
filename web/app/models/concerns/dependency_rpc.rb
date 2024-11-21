# frozen_string_literal: true

module DependencyRPC
  extend ActiveSupport::Concern

  def rpc_dependency
    Sidecar::DependencyParams.new(
      name:,
      version:,
      repository_url: repo_url,
      overrides: rpc_overrides
    )
  end

  private

  def rpc_overrides
    override_builder = info.override_builder.new(configs:)

    override_builder.create
  end
end
