# frozen_string_literal: true

class Chart::Override::Redis < Chart::Override::Base
  # https://artifacthub.io/packages/helm/bitnami/redis

  OVERRIDE_MAP = {
    cpu_cores: %w[master.resources.requests.cpu master.resources.limits.cpu],
    memory_bytes: %w[master.resources.requests.memory master.resources.limits.memory],
    disk_bytes: %w[master.persistence.size],
    max_memory_policy: %w[master.maxmemory-policy],
    db_password: %w[auth.password],
    app_version: []
  }

  VALUE_TYPES = {
    cpu_cores: :number,
    memory_bytes: :number,
    disk_bytes: :number,
    max_memory_policy: :string,
    db_password: :string,
    app_version: :string
  }.freeze

  def initialize(configs:)
    @configs = configs
  end

  def create
    @configs.map { |k, v| create_override(k, v) }.flatten
  end

  private

  def create_override(name, value)
    return [] if value.blank?

    targets = OVERRIDE_MAP[name.to_sym]
    raise "Not found config #{name}" if targets.nil?

    targets.map do |target|
      Sidecar::OverrideParams.new(
        path: target,
        value: convert_value(name, value, VALUE_TYPES)
      )
    end
  end
end
