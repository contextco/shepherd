# frozen_string_literal: true

class ProjectVersion < ApplicationRecord
  include ::VersionRPC

  belongs_to :project
  has_many :services, dependent: :destroy, class_name: "ProjectService"
  has_many :dependencies, dependent: :destroy

  has_one :helm_repo, through: :project
  has_one :helm_chart, dependent: :destroy, as: :owner

  has_one :team, through: :project

  enum :state, { draft: 0, building: 1, published: 2, failed: 3 }

  validates :version, uniqueness: { scope: :project_id }

  def next_version
    versions = project.project_versions.order(created_at: :desc)
    return nil if versions.first == self

    versions[versions.find_index(self) - 1]
  end

  def eligible_dependencies
    Chart::Dependency.all - dependencies.map(&:info)
  end

  def previous_version
    versions = project.project_versions.order(created_at: :desc)
    return nil if versions.last == self

    versions[versions.find_index(self) + 1]
  end

  def publish!
    building!
    publisher = ChartPublisher.new(rpc_chart, self)
    publisher.publish_chart!
    published!
  end

  def fork!(version_params)
    transaction do
      new_version = project.project_versions.new(version_params)
      new_version.save!
      services.each do |service|
        service = service.dup
        service.project_version = new_version
        service.save!
      end

      new_version
    end
  end

  def client_yaml_filename
    "values-#{version}.yaml"
  end

  def client_values_yaml_path
    "#{project.name}/#{project.name}-#{version}-values.yaml"
  end
end
