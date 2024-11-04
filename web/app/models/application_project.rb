# frozen_string_literal: true

class ApplicationProject < ApplicationRecord
  belongs_to :team
  validates :name, presence: true

  has_many :application_project_versions, dependent: :destroy

  def latest_version
    application_project_versions.order(:created_at).last
  end
end
