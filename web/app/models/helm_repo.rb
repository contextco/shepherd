# frozen_string_literal: true

class HelmRepo < ApplicationRecord
  belongs_to :project

  has_many :helm_users, dependent: :destroy
  validates :name, presence: true

  def valid_credentials?(name, password)
    helm_users.exists?(name:, password:)
  end
end
