# frozen_string_literal: true

class AgentInstance::StatusComponent < ApplicationComponent
  attribute :agent_instance
  delegate :subscriber, to: :agent_instance
end
