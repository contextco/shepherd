# frozen_string_literal: true

class Team < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :deployments, dependent: :destroy
  has_many :containers, dependent: :destroy
end
