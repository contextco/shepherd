# frozen_string_literal: true

class Services::ResourceSelectorComponent < ApplicationComponent
  attribute :form
  attribute :field_name
  attribute :field_label
  attribute :default_value
  attribute :default_unit

  def parent_object
    @parent_object ||= form.object.is_a?(ProjectService) ? form.object : form.object.try(:project_service)
  end
end
