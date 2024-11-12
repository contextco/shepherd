# frozen_string_literal: true

class UI::StepSliderComponent < ApplicationComponent
  attribute :form
  attribute :steps
  attribute :labels
  attribute :name

  attribute :disabled_steps, default: []
end
