# frozen_string_literal: true

class ProjectSubscriber < ApplicationRecord
  belongs_to :project

  validates :name, presence: true

  has_one :helm_repo, dependent: :destroy

  after_create_commit :setup_helm_repo

  scope :dummy, -> { where(dummy: true) }
  scope :non_dummy, -> { where(dummy: false) }

  private

  def setup_helm_repo
    create_helm_repo!(name: project.name)

    project.project_versions.each do |version|
      # TODO: this condition is a smell that we should be using a "fake" publisher in tests
      version.publish!(project_subscriber: self) unless Rails.env.test?
    end
  end
end
