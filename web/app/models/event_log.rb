class EventLog < ApplicationRecord
  belongs_to :agent_instance

  enum :event_type, { heartbeat: 0 }

  after_create_commit -> { agent_instance.update!(last_heartbeat_at: Time.now) }, if: :heartbeat?

  store_accessor :payload, :project_version_id

  def self.most_recent
    order(created_at: :desc).first
  end
end
