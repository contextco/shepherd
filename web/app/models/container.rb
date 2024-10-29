# frozen_string_literal: true

class Container < ApplicationRecord
  belongs_to :deployment
  has_many :event_logs, dependent: :destroy

  validates :lifecycle_id, presence: true
end
