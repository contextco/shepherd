# frozen_string_literal: true

class UI::FormTextFieldComponent < ApplicationComponent
  attribute :title
  attribute :caveat
  attribute :disabled, default: false

  renders_one :label
  renders_one :field
end
