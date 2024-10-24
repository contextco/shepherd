# frozen_string_literal: true

class Container < ApplicationRecord
  belongs_to :team
  belongs_to :deployment
end
