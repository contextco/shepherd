class AgentAction < ApplicationRecord
  enum :status, [ :pending, :completed, :failed ], default: :pending
  belongs_to :subscriber, class_name: "ProjectSubscriber", foreign_key: "project_subscriber_id"
  belongs_to :created_by, class_name: "User", optional: true

  def completed!
    transaction do
      update!(completed_at: Time.current)
      super
    end
  end

  def self.most_recent
    order(created_at: :desc).first
  end
end
