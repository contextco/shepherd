# frozen_string_literal: true

class Project < ApplicationRecord
  belongs_to :team
  validates :name, presence: true

  has_many :project_versions, dependent: :destroy
  has_one :latest_project_version, -> { order(created_at: :desc) }, class_name: "ProjectVersion"
  has_one :helm_repo, dependent: :destroy
  has_many :project_subscribers, dependent: :destroy

  scope :in_version_order, -> { order(created_at: :desc) }

  def published_versions
    project_versions.order(created_at: :desc).filter(&:published?)
  end

  def draft_versions
    project_versions.order(created_at: :desc).filter(&:draft?)
  end
end
