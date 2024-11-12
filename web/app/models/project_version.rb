# frozen_string_literal: true

class ProjectVersion < ApplicationRecord
  belongs_to :project
  has_many :services, dependent: :destroy, class_name: "ProjectService"
  has_one :helm_repo, through: :project
  has_one :helm_chart, dependent: :destroy, as: :owner

  has_one :team, through: :project

  enum :state, { draft: 0, building: 1, published: 2, failed: 3 }

  validates :version, presence: true, format: { with: /\A\d+\.\d+\.\d+\z/ } # semantic versioning

  def version_integer
    # monotonically increasing integer for version
    major_version * 1_000_000 + minor_version * 1000 + patch_version
  end

  def major_version
    version&.split(".")&.first&.to_i || 0
  end

  def minor_version
    version&.split(".")&.second&.to_i || 0
  end

  def patch_version
    version&.split(".")&.third&.to_i || 1
  end

  def major_version=(major_version)
    self.version = "#{major_version}.#{minor_version}.#{patch_version}"
  end

  def minor_version=(minor_version)
    self.version = "#{major_version}.#{minor_version}.#{patch_version}"
  end

  def patch_version=(patch_version)
    self.version = "#{major_version}.#{minor_version}.#{patch_version}"
  end
end
