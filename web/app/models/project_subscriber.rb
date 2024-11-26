# frozen_string_literal: true

class ProjectSubscriber < ApplicationRecord
  belongs_to :project

  validates :name, presence: true

  has_one :helm_repo, dependent: :destroy

  after_create :setup_helm_repo

  scope :dummy, -> { where(dummy: true) }
  scope :non_dummy, -> { where(dummy: false) }

  private

  def setup_helm_repo
    create_helm_repo!(name: project.name)
  end
end
