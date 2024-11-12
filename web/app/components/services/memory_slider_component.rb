# frozen_string_literal: true

class Services::MemorySliderComponent < ApplicationComponent
  attribute :form

  OPTIONS = [
    1, 2, 4, 8, 16, 32, 64
  ].map(&:gigabytes).freeze
end
