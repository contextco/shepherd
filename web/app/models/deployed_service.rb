# frozen_string_literal: true

class DeployedService < ApplicationRecord
  belongs_to :application_project_version
  has_one :team, through: :application_project_version
  has_one :helm_chart, optional: true, dependent: :destroy

  validates :name, presence: true
end
