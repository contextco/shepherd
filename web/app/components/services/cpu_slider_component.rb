# frozen_string_literal: true

class Services::CPUSliderComponent < ApplicationComponent
  attribute :form

  DEFAULT_OPTIONS = [
    1, 2, 4, 8, 16, 32
  ].freeze

  attribute :options, default: DEFAULT_OPTIONS

  def options_value
    options || DEFAULT_OPTIONS
  end
end
