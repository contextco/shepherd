class AgentAction < ApplicationRecord
  enum :status, [ :pending, :completed, :failed ], default: :pending

  belongs_to :subscriber, class_name: "ProjectSubscriber", foreign_key: "project_subscriber_id"

  # self.abstract_class = true
end
