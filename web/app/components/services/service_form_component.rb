# frozen_string_literal: true

class Services::ServiceFormComponent < ApplicationComponent
  attribute :service
  attribute :method_type, default: :post

  def service_object
    @service_object ||= service || ProjectService.new
  end

  def url
    return project_version_service_path if update?

    project_version_service_index_path
  end

  def update_create_text
    update? ? "Update" : "Create"
  end

  private

  def update?
    method_type == :patch
  end
end
