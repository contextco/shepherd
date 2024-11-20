# frozen_string_literal: true

class Dependencies::RedisComponent < DependenciesComponent
  MAX_MEMORY_POLICY_OPTIONS = [
    [ "allkeys-lru", "allkeys-lru (typical for caches)" ],
    [ "noeviction", "noeviction (typical for queues)" ],
    %w[allkeys-lfu allkeys-lfu],
    %w[allkeys-random allkeys-random],
    %w[volatile-lru volatile-lru],
    %w[volatile-lfu volatile-lfu],
    %w[volatile-random volatile-random],
    %w[volatile-ttl volatile-ttl]
  ].freeze
end
