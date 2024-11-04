# frozen_string_literal: true

class ApplicationProject < ApplicationRecord
  belongs_to :team
  validates :name, presence: true

  has_many :application_project_versions, dependent: :destroy
end
