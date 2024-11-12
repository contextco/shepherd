# frozen_string_literal: true

class UI::DynamicNestedForm::CustomAddHandlerComponent < ApplicationComponent
  attribute :event
  attribute :prevent_default, default: true
  attribute :for_id
end
