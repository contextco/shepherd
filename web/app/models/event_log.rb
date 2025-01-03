class EventLog < ApplicationRecord
  belongs_to :agent_instance

  enum :event_type, { heartbeat: 0 }

  after_create_commit -> { agent_instance.update!(last_heartbeat_at: Time.now) }, if: :heartbeat?
end
