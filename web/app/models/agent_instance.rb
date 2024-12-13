# frozen_string_literal: true

class AgentInstance < ApplicationRecord
  HEARTBEAT_TIMEOUT = 5.minutes

  belongs_to :project_subscriber
  has_many :event_logs, dependent: :destroy
  has_many :heartbeat_logs, -> { heartbeat }, class_name: "EventLog", dependent: :destroy

  enum :status, { healthy: 0, unresponsive: 1, terminated: 2, crashed: 3 }

  validates :lifecycle_id, presence: true

  after_find :update_status

  def last_heartbeat_time
    @last_heartbeat_time ||= heartbeat_logs.last&.created_at
  end

  def unhealthy?
    unresponsive? || crashed?
  end

  private

  def update_status
    return unless last_heartbeat_time.present?

    if last_heartbeat_time < HEARTBEAT_TIMEOUT.ago
      update!(status: :unresponsive) unless unresponsive?
    else
      update!(status: :healthy) unless healthy?
    end
  end
end
