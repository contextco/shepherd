# frozen_string_literal: true

class ProjectSubscriber < ApplicationRecord
  belongs_to :project

  validates :name, presence: true
end
