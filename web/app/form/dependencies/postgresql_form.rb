# frozen_string_literal: true

class Dependencies::PostgresqlForm < Dependencies::Base
  validate :version_inclusion

  CPU_CORES_OPTIONS = [
    1, 2, 4, 8, 16, 32
  ].freeze

  MEMORY_OPTIONS = [
    1.gigabyte, 2.gigabytes, 4.gigabytes, 8.gigabytes, 16.gigabytes, 32.gigabytes
  ].freeze

  DISK_OPTIONS = [
    10.gigabytes, 20.gigabytes, 40.gigabytes, 80.gigabytes, 160.gigabytes, 320.gigabytes
  ].freeze

  attribute :configs do
    attribute :db_name, default: "default_db_name"
    attribute :db_user, default: "default_db_username"
    attribute :cpu_cores, :integer
    attribute :memory_bytes, :integer
    attribute :disk_bytes, :integer

    validates :cpu_cores, presence: true, inclusion: { in: CPU_CORES_OPTIONS }, numericality: { only_integer: true }
    validates :memory_bytes, presence: true, inclusion: { in: MEMORY_OPTIONS }, numericality: { only_integer: true }
    validates :disk_bytes, presence: true, inclusion: { in: DISK_OPTIONS }, numericality: { only_integer: true }

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

  def version_inclusion
    return if Chart::Dependency.from_name("postgresql").variants.map(&:version).include?(version)

    errors.add(:version, "is not a valid version")
  end
end
