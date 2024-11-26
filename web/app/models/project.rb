# frozen_string_literal: true

class Project < ApplicationRecord
  belongs_to :team
  validates :name, presence: true

  has_many :project_versions, dependent: :destroy
  has_one :latest_project_version, -> { order(created_at: :desc) }, class_name: "ProjectVersion"

  has_many :project_subscribers, dependent: :destroy
  has_one :dummy_project_subscriber, -> { dummy }, class_name: "ProjectSubscriber"
  has_many :non_dummy_project_subscribers, -> { non_dummy }, class_name: "ProjectSubscriber"

  after_create_commit :setup_dummy_subscriber

  scope :in_version_order, -> { order(created_at: :desc) }

  def published_versions
    project_versions.order(created_at: :desc).filter(&:published?)
  end

  def draft_versions
    project_versions.order(created_at: :desc).filter(&:draft?)
  end

  private

  def setup_dummy_subscriber
    project_subscribers.create!(name: "Dummy", dummy: true)
  end
end
