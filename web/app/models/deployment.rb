# frozen_string_literal: true

class Deployment < ApplicationRecord
  belongs_to :team
  has_many :containers, dependent: :destroy
  has_many :event_logs, through: :containers
  has_many :heartbeat_logs, -> { heartbeat }, through: :containers, source: :event_logs

  validates :name, presence: true

  has_many :tokens, class_name: "Deployment::Token", dependent: :destroy

  after_create -> { tokens.create! }

  def containers_by_name
    containers.group_by(&:name)
  end
end
