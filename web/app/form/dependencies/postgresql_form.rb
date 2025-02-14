# frozen_string_literal: true

class Dependencies::PostgresqlForm < Dependencies::Base
  CPU_CORES_OPTIONS = [
    1, 2, 4, 8, 16, 32
  ].freeze

  MEMORY_OPTIONS = [
    1.gigabyte, 2.gigabytes, 4.gigabytes, 8.gigabytes, 16.gigabytes, 32.gigabytes
  ].freeze

  DISK_OPTIONS = [
    10.gigabytes, 20.gigabytes, 40.gigabytes, 80.gigabytes, 160.gigabytes, 320.gigabytes
  ].freeze

  # two sources of truth for app versions, also in data.rb, TODO: fix
  APP_VERSIONS = %w[15.10.0 16.6.0 17.2.0].freeze


  attribute :configs do
    attribute :db_name
    attribute :db_user
    attribute :db_password # this is never set from ui, only generated
    attribute :cpu_cores, :integer
    attribute :memory_bytes, :integer
    attribute :disk_bytes, :integer
    attribute :app_version

    validates :cpu_cores, presence: true, inclusion: { in: CPU_CORES_OPTIONS }, numericality: { only_integer: true }
    validates :memory_bytes, presence: true, inclusion: { in: MEMORY_OPTIONS }, numericality: { only_integer: true }
    validates :disk_bytes, presence: true, inclusion: { in: DISK_OPTIONS }, numericality: { only_integer: true }
    validates :app_version, presence: true, inclusion: { in: APP_VERSIONS }

    validate :valid_postgresql_db_name
    validate :valid_postgresql_db_user

    def valid_postgresql_db_name
      return if db_name.blank?
      return if db_name.match?(/^[a-zA-Z_][a-zA-Z0-9_]*$/)

      errors.add(:db_name, "must start with a letter or underscore and contain only letters, numbers, and underscores")
    end

    def valid_postgresql_db_user
      return if db_user.blank?
      return if db_user.match?(/^[a-zA-Z_][a-zA-Z0-9_]*$/)

      errors.add(:db_user, "must start with a letter or underscore and contain only letters, numbers, and underscores")
    end
  end

  def db_connection_string
    "postgresql://#{configs.db_user}:#{configs.db_password}@#{name}/#{configs.db_name}"
  end

  def update_dependency(dependency)
    configs = dependency.configs.symbolize_keys.merge(configs_params.except(:db_password)) # don't update password
    dependency.update!(name:, version:, repo_url:, chart_name:, configs:)
  end

  private

  def configs_params
    {
      db_name: configs.db_name.present? ? configs.db_name : postgresql_dbname_generator,
      db_user: configs.db_user.present? ? configs.db_user : postgresql_username_generator,
      db_password: postgresql_password_generator,
      cpu_cores: configs.cpu_cores,
      memory_bytes: configs.memory_bytes,
      disk_bytes: configs.disk_bytes,
      app_version: configs.app_version
    }
  end

  def postgresql_username_generator
    "user_#{SecureRandom.hex(6)}"
  end

  def postgresql_dbname_generator
    "db_#{SecureRandom.hex(6)}"
  end

  def postgresql_password_generator
    SecureRandom.hex(16)
  end
end
