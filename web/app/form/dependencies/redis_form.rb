# frozen_string_literal: true

class Dependencies::RedisForm < Dependencies::Base
  CPU_CORES_OPTIONS = [
    1, 2, 4, 8, 16, 32
  ].freeze

  MEMORY_OPTIONS = [
    1.gigabyte, 2.gigabytes, 4.gigabytes, 8.gigabytes, 16.gigabytes, 32.gigabytes, 64.gigabytes
  ].freeze

  DISK_OPTIONS = [
    10.gigabytes, 20.gigabytes, 40.gigabytes, 80.gigabytes, 160.gigabytes, 320.gigabytes
  ].freeze


  attribute :configs do
    attribute :max_memory_policy
    attribute :cpu_cores, :integer
    attribute :memory_bytes, :integer
    attribute :disk_bytes, :integer

    attribute :db_password # this is never set from ui, only generated

    validates :max_memory_policy, presence: true, inclusion: { in: Dependencies::RedisComponent::MAX_MEMORY_POLICY_OPTIONS.map(&:first) }
    validates :cpu_cores, presence: true, inclusion: { in: CPU_CORES_OPTIONS }, numericality: { only_integer: true }
    validates :memory_bytes, presence: true, inclusion: { in: MEMORY_OPTIONS }, numericality: { only_integer: true }
    validates :disk_bytes, presence: true, inclusion: { in: DISK_OPTIONS }, numericality: { only_integer: true }
  end

  def configs_params
    {
      max_memory_policy: configs.max_memory_policy,
      cpu_cores: configs.cpu_cores,
      memory_bytes: configs.memory_bytes,
      disk_bytes: configs.disk_bytes,
      db_password: postgresql_password_generator
    }
  end

  def update_dependency(dependency)
    configs = dependency.configs.symbolize_keys.merge(configs_params.except(:db_password)) # don't update password
    dependency.update!(name:, version:, repo_url:, chart_name:, configs:)
  end

  private

  def postgresql_password_generator
    SecureRandom.hex(16)
  end
end
