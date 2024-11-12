# frozen_string_literal: true

class UI::DynamicNestedForm::AddButtonComponent < ApplicationComponent
  attribute :for_id

  renders_one :button
end
