# frozen_string_literal: true

class Dependencies::Base
  include FormObject

  attribute :name
  attribute :version
  attribute :repo_url

  validates :name, presence: true
  validates :repo_url, presence: true
  validates :version, presence: true

  def create_dependency(project_version)
    project_version.dependencies.create!(name:, version:, repo_url:, configs: configs.attributes)
  end
end
