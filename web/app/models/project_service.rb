# frozen_string_literal: true

class ProjectService < ApplicationRecord
  include ::ServiceRPC

  delegate :project, to: :project_version
  belongs_to :project_version
  has_one :team, through: :project_version
  has_one :helm_chart, dependent: :destroy, as: :owner
  has_one :helm_repo, through: :project_version

  validates :name, presence: true

  def environment_variables
    super&.map(&:with_indifferent_access)
  end

  def image_tag
    DockerImageUrlParser.new(image).tag
  end

  def image_without_tag
    DockerImageUrlParser.new(image).to_s(with_tag: false)
  end

  def client_values_yaml_path
    "#{project.name}/#{name}-#{project_version.version}-values.yaml"
  end
end
