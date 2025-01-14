# frozen_string_literal: true

class ProjectSubscriber < ApplicationRecord
  has_secure_token :password

  belongs_to :project_version
  delegate :project, to: :project_version

  validates :name, presence: true

  has_one :helm_repo, dependent: :destroy

  has_many :agent_instances, dependent: :destroy
  has_many :event_logs, through: :agent_instances
  has_many :heartbeat_logs, -> { heartbeat }, through: :agent_instances, source: :event_logs
  has_many :tokens, class_name: "ProjectSubscriber::Token", dependent: :destroy
  has_many :agent_actions
  has_many :apply_version_actions, class_name: "AgentAction::ApplyVersion"

  # after_create_commit :setup_helm_repo
  after_create -> { tokens.create! }

  scope :dummy, -> { where(dummy: true) }
  scope :non_dummy, -> { where(dummy: false) }

  def assign_to_new_version!(new_version, created_by: nil)
    assert_charts_in_repo!(new_version)

    transaction do
      apply_version_actions.create!(
        source_version_id: project_version.id,
        target_version_id: new_version.id,
        created_by:
      )
      update!(project_version: new_version)
    end
  end

  def eligible_for_new_action?
    return true if agent_actions.blank?

    agent_actions.most_recent.completed?
  end

  def authenticate(user_password)
    password == user_password
  end

  def most_recent_version
    project.published_versions.first
  end

  def agent_instances_by_name
    agent_instances.group_by(&:name)
  end

  def online?
    agent_instances.healthy.present?
  end

  def installable_chart
    helm_repo.client.chart_file(project_version)
  end

  def last_heartbeat_at
    agent_instances.maximum(:last_heartbeat_at)
  end

  def currently_running_version
    heartbeat_logs.most_recent&.project_version
  end

  def setup_helm_repo!
    create_helm_repo!(name: project.name)
    assert_charts_in_repo!(project_version)
  end

  private

  def assert_charts_in_repo!(version)
    Chart::Publisher.publish!(version, self)
  end
end
