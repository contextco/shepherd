class EventLog < ApplicationRecord
  belongs_to :container

  enum :event_type, { heartbeat: 0 }
end
