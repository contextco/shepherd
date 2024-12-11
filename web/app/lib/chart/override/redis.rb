# frozen_string_literal: true

class Chart::Override::Redis < Chart::Override::Base
  # https://artifacthub.io/packages/helm/bitnami/redis

  OVERRIDE_MAP = {
    cpu_cores: %w[master.resources.requests.cpu master.resources.limits.cpu],
    memory_bytes: %w[master.resources.requests.memory master.resources.limits.memory],
    disk_bytes: %w[master.persistence.size],
    max_memory_policy: %w[master.extraFlags],
    db_password: %w[auth.password],
    architecture: %w[architecture],
    app_version: []
  }

  VALUE_TYPES = {
    cpu_cores: :number,
    memory_bytes: :number,
    disk_bytes: :string,
    max_memory_policy: :list,
    db_password: :string,
    architecture: :string,
    app_version: :string
  }.freeze

  VALUE_TRANSFORMS = {
    disk_bytes: ->(v) { "#{ActiveSupport::NumberHelper.number_to_human_size(v).to_i}Gi" },
    max_memory_policy: ->(v) { Google::Protobuf::ListValue.new(
      values: [
        Google::Protobuf::Value.new(string_value: "--maxmemory-policy #{v}")
      ]
    ) }
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

    yaml_targets = OVERRIDE_MAP[name.to_sym] or raise "Not found config #{name}"
    value_type = VALUE_TYPES[name.to_sym] or raise "Not found value type for #{name}"

    transform_proc = VALUE_TRANSFORMS[name.to_sym]
    yaml_targets.map do |target|
      Sidecar::OverrideParams.new(
        path: target,
        value: convert_value(name, value, value_type, &transform_proc)
      )
    end
  end
end
