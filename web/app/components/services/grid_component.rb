# frozen_string_literal: true

class Services::GridComponent < ApplicationComponent
  attribute :project_version

  def services
    project_version&.services || []
  end

  def dependencies
    project_version&.dependencies
  end

  def enabled_add_service_button?
    services.count < 1
  end
end
