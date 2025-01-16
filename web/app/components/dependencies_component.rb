# frozen_string_literal: true

class DependenciesComponent < ApplicationComponent
  attribute :dependency_instance
  attribute :dependency_info
  attribute :version
  attribute :form_method, default: :post
  attribute :disabled, default: false

  def initialize(**args)
    super
    self.dependency_instance ||= dependency_info.form.new
  end

  def url
    update? ? dependency_path(dependency_instance.dependency.id) : version_dependencies_path(version)
  end

  def update_create_text
    update? ? "Update" : "Create"
  end

  def update?
    form_method == :patch
  end
end
