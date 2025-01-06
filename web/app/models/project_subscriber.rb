# frozen_string_literal: true

class ProjectSubscriber < ApplicationRecord
  has_secure_token :password

  belongs_to :project

  validates :name, presence: true

  has_one :helm_repo, dependent: :destroy

  has_many :agent_instances, dependent: :destroy
  has_many :event_logs, through: :agent_instances
  has_many :heartbeat_logs, -> { heartbeat }, through: :agent_instances, source: :event_logs
  has_many :tokens, class_name: "ProjectSubscriber::Token", dependent: :destroy

  after_create_commit :setup_helm_repo
  after_create -> { tokens.create! }

  scope :dummy, -> { where(dummy: true) }
  scope :non_dummy, -> { where(dummy: false) }

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

  def last_heartbeat_at
    agent_instances.maximum(:last_heartbeat_at)
  end

  private

  def setup_helm_repo
    create_helm_repo!(name: project.name)

    project.project_versions.each do |version|
      next unless version.published?
      # TODO: this condition is a smell that we should be using a "fake" publisher in tests
      version.publish!(project_subscriber: self) unless Rails.env.test?
    end
  end
end
