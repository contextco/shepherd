# frozen_string_literal: true

class Chart::Override::Postgresql < Chart::Override::Base
  # https://artifacthub.io/packages/helm/bitnami/postgresql
  OVERRIDE_MAP = {
    db_name: %w[auth.database],
    db_user: %w[auth.username],
    db_password: %w[auth.password],
    cpu_cores: %w[primary.resources.requests.cpu primary.resources.limits.cpu],
    memory_bytes: %w[primary.resources.requests.memory primary.resources.limits.memory],
    disk_bytes: %w[primary.persistence.size],
    app_version: %w[image.tag]
  }

  VALUE_TYPES = {
    db_name: :string,
    db_user: :string,
    db_password: :string,
    cpu_cores: :number,
    memory_bytes: :number,
    disk_bytes: :string,
    app_version: :string
  }.freeze

  VALUE_TRANSFORMS = {
    disk_bytes: ->(v) { "#{ActiveSupport::NumberHelper.number_to_human_size(v).to_i}Gi" }
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

    transform_proc = VALUE_TRANSFORMS[name.to_sym]
    yaml_targets.map do |target|
      Sidecar::OverrideParams.new(
        path: target,
        value: convert_value(name, value, VALUE_TYPES, &transform_proc)
      )
    end
  end
end
