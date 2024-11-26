# frozen_string_literal: true

class ProjectVersion < ApplicationRecord
  include ::VersionRPC

  belongs_to :project
  has_many :services, dependent: :destroy, class_name: "ProjectService"
  has_many :dependencies, dependent: :destroy

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

  def publish!(project_subscriber: nil)
    building!
    # could we do this more elegantly by keeping track in helm_repo model of already published versions?
    # TODO: investigate and potentially fix
    helm_repos = project_subscriber&.helm_repo || project.project_subscribers.map(&:helm_repo)
    helm_repos = [ helm_repos ] unless helm_repos.is_a?(Array)
    publisher = Chart::Publisher.new(rpc_chart, helm_repos)
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

      dependencies.each do |dependency|
        dependency = dependency.dup
        dependency.project_version = new_version
        dependency.save!
      end

      new_version
    end
  end
end
