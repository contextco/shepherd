# frozen_string_literal: true

class Services::ResourcesViewComponent < ApplicationComponent
  attribute :service

  def cpu_cores
    return service.cpu_cores&.to_i if service.respond_to?(:cpu_cores)

    service.configs["cpu_cores"]&.to_i if service.respond_to?(:configs)
  end

  def memory_bytes
    return service.memory_bytes if service.respond_to?(:memory_bytes)

    service.configs["memory_bytes"] if service.respond_to?(:configs)
  end

  def disk_bytes
    return service.disk_bytes if service.respond_to?(:disk_bytes)

    service.configs["disk_bytes"] if service.respond_to?(:configs)
  end
end
