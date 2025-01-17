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

  def enforces_version_consistency?
    # fields like name cannot change between versions, but can be updated if this is the first version and is unpublished
    return true if disabled

    previous_version = version.previous_version
    return false if previous_version.nil?

    # if previous version has a dependency with the same name, then we can't update
    return true if previous_version.dependencies.any? { |d| d.info.name == dependency_info.name }

    false
  end
end
