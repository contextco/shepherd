# frozen_string_literal: true

class Services::ServiceFormComponent < ApplicationComponent
  attribute :service_form_object
  attribute :form_method, default: :post

  def service_object
    @service_object ||= service_form_object || Service::Form.empty
  end

  def update_create_text
    update? ? "Update" : "Create"
  end

  def url
    update? ? project_service_path(service_form_object.service_id) : services_path
  end

  private

  def update?
    form_method == :patch
  end
end
