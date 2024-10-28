# frozen_string_literal: true

class Deployment < ApplicationRecord
  belongs_to :team
  has_many :containers, dependent: :destroy

  validates :name, presence: true

  has_many :tokens, class_name: 'Deployment::Token', dependent: :destroy

  after_create -> { tokens.create! }
end
