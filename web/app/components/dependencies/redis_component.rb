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

  def db_connection_string
    return if dependency_instance&.dependency.nil?

    dependency = dependency_instance.dependency
    password = dependency.configs["db_password"]
    namespace_name = dependency.project.name
    # note schema here is HELM_RELEASE_NAME-redis-master.NAMESPACE_NAME.svc.cluster.local
    host = "#{dependency.project.name}-redis-master.#{namespace_name}.svc.cluster.local"

    "redis://:#{password}@#{host}:6379"
  end
end
