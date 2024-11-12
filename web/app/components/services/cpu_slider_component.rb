# frozen_string_literal: true

class Services::CPUSliderComponent < ApplicationComponent
  attribute :form

  OPTIONS = [
    1, 2, 4, 8, 16, 32
  ].freeze
end
