# frozen_string_literal: true

class Services::MemorySliderComponent < ApplicationComponent
  attribute :form

  DEFAULT_OPTIONS = [
    1, 2, 4, 8, 16, 32, 64
  ].map(&:gigabytes).freeze

  attribute :options, default: DEFAULT_OPTIONS
end
