# frozen_string_literal: true

module Maintenance
  class MigrateProjectIdsOnSubscribersTask < MaintenanceTasks::Task
    def collection
      ProjectSubscriber.all
    end

    def process(element)
      project = Project.find(element.project_id)
      element.update!(project_version_id: project.project_versions.published.order(created_at: :desc).first.id)
    end

    delegate :count, to: :collection
  end
end
