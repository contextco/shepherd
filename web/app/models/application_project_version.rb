# frozen_string_literal: true

class ApplicationProjectVersion < ApplicationRecord
  belongs_to :application_project
  has_many :deployed_services, dependent: :destroy
  has_one :helm_chart, dependent: :destroy, as: :owner

  has_one :team, through: :application_project

  enum :state, { draft: 0, building: 1, published: 2, failed: 3 }

  validates :version, presence: true, format: { with: /\A\d+\.\d+\.\d+\z/ } # semantic versioning
end
