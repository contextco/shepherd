# frozen_string_literal: true

class AgentInstance < ApplicationRecord
  HEALTHY_TIMEOUT = 2.minutes

  belongs_to :subscriber, class_name: "ProjectSubscriber", foreign_key: "project_subscriber_id"
  has_many :event_logs, dependent: :destroy
  has_many :heartbeat_logs, -> { heartbeat }, class_name: "EventLog", dependent: :destroy

  validates :lifecycle_id, presence: true

  def healthy?
    last_heartbeat_at.present? && last_heartbeat_at < HEALTHY_TIMEOUT.ago
  end

  def self.healthy
    where("last_heartbeat_at > ?", HEALTHY_TIMEOUT.ago)
  end

  def self.healthy_and_recently_unresponsive(threshold: 1.day)
    where("last_heartbeat_at > ?", HEALTHY_TIMEOUT.ago - threshold)
      .order("last_heartbeat_at > ? DESC", HEALTHY_TIMEOUT.ago)
  end

  def currently_running_version
    heartbeat_logs.most_recent&.project_version
  end
end
