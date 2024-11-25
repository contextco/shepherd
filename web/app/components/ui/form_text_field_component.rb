# frozen_string_literal: true

class UI::FormTextFieldComponent < ApplicationComponent
  attribute :title

  renders_one :label
  renders_one :field
end
