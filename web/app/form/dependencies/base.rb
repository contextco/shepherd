# frozen_string_literal: true

class Dependencies::Base
  include FormObject

  attribute :dependency

  attribute :name
  attribute :version
  attribute :repo_url

  validates :name, presence: true
  validates :repo_url, presence: true
  validates :version, presence: true

  def create_dependency(project_version)
    project_version.dependencies.create!(name:, version:, repo_url:, configs: configs_params)
  end

  def update_dependency(dependency)
    dependency.update!(name:, version:, repo_url:, configs: configs_params)
  end

  def self.from_dependency(dependency)
    # override as needed in child forms
    f = self.new
    f.assign_attributes(
      dependency: dependency,
      name: dependency.name,
      version: dependency.version,
      repo_url: dependency.repo_url,
      configs: dependency.configs
    )

    f
  end
end
