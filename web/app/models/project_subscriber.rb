# frozen_string_literal: true

class ProjectSubscriber < ApplicationRecord
  has_secure_token :password

  belongs_to :project

  validates :name, presence: true

  has_one :helm_repo, dependent: :destroy

  after_create_commit :setup_helm_repo

  scope :dummy, -> { where(dummy: true) }
  scope :non_dummy, -> { where(dummy: false) }

  def authenticate(user_password)
    password == user_password
  end

  private

  def setup_helm_repo
    create_helm_repo!(name: project.name)

    project.project_versions.each do |version|
      # TODO: this condition is a smell that we should be using a "fake" publisher in tests
      version.publish!(project_subscriber: self) unless Rails.env.test?
    end
  end
end
