# frozen_string_literal: true

class Chart::Override::Postgresql < Chart::Override::Base
  # https://artifacthub.io/packages/helm/bitnami/postgresql
  OVERRIDE_MAP = {
    db_name: %w[primary.database],
    db_user: %w[auth.username],
    cpu_cores: %w[primary.resources.requests.cpu primary.resources.limits.cpu],
    memory_bytes: %w[primary.resources.requests.memory primary.resources.limits.memory],
    disk_bytes: %w[primary.persistence.size]
  }

  VALUE_TYPES = {
    db_name: :string,
    db_user: :string,
    cpu_cores: :number,
    memory_bytes: :number,
    disk_bytes: :number
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
