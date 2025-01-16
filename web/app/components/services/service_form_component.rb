# frozen_string_literal: true

class Services::ServiceFormComponent < ApplicationComponent
  attribute :service_form_object
  attribute :form_method, default: :post
  attribute :version # hack, we can def remove this somehow.
  attribute :disabled, default: false

  def service_object
    @service_object ||= service_form_object || Service::Form.empty
  end

  def update_create_text
    update? ? "Update" : "Create"
  end

  def url
    update? ? project_service_path(service_form_object.service_id) : version_project_services_path(version_id: version.id)
  end

  private

  def update?
    form_method == :patch
  end

  def enforces_version_consistency?
    # fields like name cannot change between versions
    # It can be updated if this is the first version where it exists and is unpublished
    return true if disabled

    previous_version = version.previous_version
    return false if previous_version.nil?

    # if previous version has a service with the same name, then we can't update
    return true if previous_version.services.any? { |s| s.name == service_object.name }

    false
  end
end
