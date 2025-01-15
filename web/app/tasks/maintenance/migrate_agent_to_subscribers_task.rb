# frozen_string_literal: true

module Maintenance
  class MigrateAgentToSubscribersTask < MaintenanceTasks::Task
    def collection
      ProjectVersion.all
    end

    def process(element)
      element.subscribers.each do |subscriber|
        subscriber.update!(agent: element.agent)
      end
    end

    delegate :count, to: :collection
  end
end
