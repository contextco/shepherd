# frozen_string_literal: true

class Dependencies::RedisForm < Dependencies::Base
  validate :version_inclusion

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

    validates :max_memory_policy, presence: true, inclusion: { in: Dependencies::RedisComponent::MAX_MEMORY_POLICY_OPTIONS.map(&:first) }
    validates :cpu_cores, presence: true, inclusion: { in: CPU_CORES_OPTIONS }, numericality: { only_integer: true }
    validates :memory_bytes, presence: true, inclusion: { in: MEMORY_OPTIONS }, numericality: { only_integer: true }
    validates :disk_bytes, presence: true, inclusion: { in: DISK_OPTIONS }, numericality: { only_integer: true }
  end

  def version_inclusion
    return if Chart::Dependency.from_name("redis").variants.map(&:version).include?(version)

    errors.add(:version, "is not a valid version")
  end
end
