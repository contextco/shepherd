# frozen_string_literal: true

class DependenciesComponent < ApplicationComponent
  attribute :dependency_instance
  attribute :dependency_info

  def update_create_text
    dependency_instance.new_record? ? "Create" : "Update"
  end
end
