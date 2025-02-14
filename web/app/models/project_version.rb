# frozen_string_literal: true

class ProjectVersion < ApplicationRecord
  belongs_to :project
  has_many :services, dependent: :destroy, class_name: "ProjectService"
  has_many :dependencies, dependent: :destroy

  has_many :subscribers, dependent: :destroy, class_name: "ProjectSubscriber"
  has_one :dummy_project_subscriber, -> { dummy }, class_name: "ProjectSubscriber"
  has_many :non_dummy_project_subscribers, -> { non_dummy }, class_name: "ProjectSubscriber"

  has_one :team, through: :project

  enum :state, { draft: 0, building: 1, published: 2, failed: 3 }

  validates :version, uniqueness: { scope: :project_id }

  def secrets
    services.flat_map(&:secrets)
  end

  def ingresses
    services.map(&:ingress_port).compact
  end

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

  def fork!(version_params)
    transaction do
      new_version = dup
      new_version.assign_attributes(version_params.merge(state: :draft))
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

      new_version.reload
    end
  end

  def deployable?
    services.any?
  end

  # Compares the current project version with an incoming version.
  #
  # @param incoming_version [ProjectVersion] The version to compare against.
  # @return [Comparisons::Version::VersionComparison] The comparison result.
  def compare(incoming_version)
    Comparisons::Version::VersionComparison.from(self, incoming_version)
  end
end
