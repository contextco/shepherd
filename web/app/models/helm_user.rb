# frozen_string_literal: true

class HelmUser < ApplicationRecord
  belongs_to :project

  validates :project, presence: true
  validates :name, presence: true
  validates :password, presence: true
end
