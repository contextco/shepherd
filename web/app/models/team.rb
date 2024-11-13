# frozen_string_literal: true

class Team < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :deployments, dependent: :destroy
  has_many :containers, dependent: :destroy

  has_many :projects, dependent: :destroy
  has_many :project_versions, through: :projects
  has_many :services, dependent: :destroy, through: :project_versions, class_name: "ProjectService"

  def setup_scaffolding!(name, description)
    transaction do
      app = projects.create!(name:)
      version = app.project_versions.create!(
        description:,
        version: "0.0.1",
        state: :draft
      )
      repo = app.create_helm_repo!(name: app.name)
      repo.helm_users.create!(
        name: "#{name}-user",
        password: SecureRandom.hex(16)
      )

      version
    end
  end
end
