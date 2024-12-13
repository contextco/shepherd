class EventLog < ApplicationRecord
  belongs_to :agent_instance

  enum :event_type, { heartbeat: 0 }
end
