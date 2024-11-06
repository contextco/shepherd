# frozen_string_literal: true

class Services::ServiceFormComponent < ApplicationComponent
  attribute :service, default: -> { ProjectService.new }

  def url
    return project_version_service_path if service.persisted?

    project_version_service_index_path
  end

  def method
    service.persisted? ? :patch : :post
  end

  def update_create_text
    service.persisted? ? "Update" : "Create"
  end
end
