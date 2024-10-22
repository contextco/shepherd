# frozen_string_literal: true

class Deployment < ApplicationRecord
  belongs_to :team
  has_many :containers, dependent: :destroy
end
