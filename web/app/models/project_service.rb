# frozen_string_literal: true

class ProjectService < ApplicationRecord
  include ::ServiceRPC

  belongs_to :project_version
  has_one :team, through: :project_version
  has_one :helm_chart, dependent: :destroy, as: :owner
  has_one :helm_repo, through: :project_version

  validates :name, presence: true
  validates :resources, presence: true

  store_accessor :resources, :cpu_request, :memory_request

  def image_tag
    DockerImageUrlParser.new(image).tag
  end

  def image_without_tag
    DockerImageUrlParser.new(image).to_s(with_tag: false)
  end
end
