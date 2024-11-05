# frozen_string_literal: true

class Project < ApplicationRecord
  belongs_to :team
  validates :name, presence: true

  has_many :project_versions, dependent: :destroy

  def latest_version
    project_versions.order(:created_at).last
  end
end
