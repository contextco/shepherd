# frozen_string_literal: true

class Team < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :deployments, dependent: :destroy
  has_many :containers, dependent: :destroy

  has_many :projects, dependent: :destroy
  has_many :project_versions, through: :projects
  has_many :services, dependent: :destroy, through: :project_versions, class_name: "ProjectService"
  has_many :dependencies, dependent: :destroy, through: :project_versions, class_name: "Dependency"
  has_many :subscribers, through: :projects, class_name: "ProjectSubscriber"

  def setup_scaffolding!(name, description)
    transaction do
      project = projects.create!(name:)
      version = project.project_versions.create!(
        description:,
        version: "0.0.1",
        state: :draft
      )

      version
    end
  end
end
