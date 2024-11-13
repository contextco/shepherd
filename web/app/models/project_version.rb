# frozen_string_literal: true

class ProjectVersion < ApplicationRecord
  belongs_to :project
  has_many :services, dependent: :destroy, class_name: "ProjectService"
  has_one :helm_repo, through: :project
  has_one :helm_chart, dependent: :destroy, as: :owner

  has_one :team, through: :project

  enum :state, { draft: 0, building: 1, published: 2, failed: 3 }

  def next_version
    versions = project.project_versions.order(created_at: :desc)
    return nil if versions.first == self

    versions[versions.find_index(self) - 1]
  end

  def previous_version
    versions = project.project_versions.order(created_at: :desc)
    return nil if versions.last == self

    versions[versions.find_index(self) + 1]
  end
end
