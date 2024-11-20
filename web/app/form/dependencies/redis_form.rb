# frozen_string_literal: true

class Dependencies::RedisForm < Dependencies::Base
  validate :version_inclusion

  attribute :configs do
    attribute :max_memory_policy
    attribute :cpu_cores, :integer
    attribute :memory_bytes, :integer
    attribute :disk_bytes, :integer

    validates :max_memory_policy, presence: true, inclusion: { in: Dependencies::RedisComponent::MAX_MEMORY_POLICY_OPTIONS.map(&:first) }
    validates :cpu_cores, presence: true, inclusion: { in: Services::CPUSliderComponent::OPTIONS }, numericality: { only_integer: true }
    validates :memory_bytes, presence: true, inclusion: { in: Services::MemorySliderComponent::OPTIONS }, numericality: { only_integer: true }
    validates :disk_bytes, presence: true, inclusion: { in: Services::DiskSliderComponent::OPTIONS }, numericality: { only_integer: true }
  end

  def version_inclusion
    return if Chart::Dependency.from_name("redis").variants.map(&:version).include?(version)

    errors.add(:version, "is not a valid version")
  end
end
