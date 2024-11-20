# frozen_string_literal: true

class UI::StepSliderComponent < ApplicationComponent
  attribute :form
  attribute :steps
  attribute :labels
  attribute :name

  attribute :disabled_steps, default: []

  def value
    # return steps.find_index(form.object&.send(:name)) if form.object&.respond_to?(:name)
    #
    # steps.find_index(form.object&.configs&.fetch(:name, nil))
  end
end
