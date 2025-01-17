# frozen_string_literal: true

class UI::FormMultiFieldComponent < ApplicationComponent
  attribute :title
  attribute :form
  attribute :association_name
  attribute :model_class
  attribute :vertical, default: false

  attribute :disabled, default: false

  attribute :caveat, default: nil

  attribute :child_component

  renders_one :label
  renders_one :header

  def unique_id
    # random id to be used for html element
    @unique_id ||= "unique-#{SecureRandom.hex(5)}"
  end
end
