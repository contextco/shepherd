# frozen_string_literal: true

class UI::FormMultiFieldComponent < ApplicationComponent
  attribute :title
  attribute :form
  attribute :association_name
  attribute :model_class

  attribute :child_component

  renders_one :label

  def unique_id
    @unique_id ||= SecureRandom.alphanumeric(10)
  end
end
