# frozen_string_literal: true

class ProjectVersion < ApplicationRecord
  belongs_to :project
  has_many :project_services, dependent: :destroy
  has_one :helm_repo, through: :project
  has_one :helm_chart, dependent: :destroy, as: :owner

  has_one :team, through: :project

  enum :state, { draft: 0, building: 1, published: 2, failed: 3 }

  validates :version, presence: true, format: { with: /\A\d+\.\d+\.\d+\z/ } # semantic versioning
end
