# frozen_string_literal: true

class HelmUser < ApplicationRecord
  belongs_to :helm_repo

  validates :helm_repo, presence: true
  validates :name, presence: true
  validates :password, presence: true
end
