# frozen_string_literal: true

class ProjectService < ApplicationRecord
  belongs_to :project_version
  has_one :team, through: :project_version
  has_one :helm_chart, dependent: :destroy

  validates :name, presence: true
end
