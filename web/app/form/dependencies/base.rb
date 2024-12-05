# frozen_string_literal: true

class Dependencies::Base
  include FormObject

  attribute :dependency
  attribute :name

  validates :name, presence: true
  validates :repo_url, presence: true
  validates :chart_name, presence: true
  validates :version, presence: true

  def create_dependency(project_version)
    project_version.dependencies.create!(name:, version:, repo_url:, chart_name:, configs: configs_params)
  end

  def update_dependency(dependency)
    dependency.update!(name:, version:, repo_url:, chart_name:, configs: configs_params)
  end

  def self.from_dependency(dependency)
    # override as needed in child forms
    f = self.new
    f.assign_attributes(
      dependency: dependency,
      name: dependency.name,
      configs: dependency.configs
    )

    f
  end

  private

  def info
    @info ||= Chart::Dependency.from_name(name)
  end

  delegate :version, :chart_name, :repository, to: :info
  alias_method :repo_url, :repository
end
