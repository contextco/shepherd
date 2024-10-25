# frozen_string_literal: true

module FormObject
  def self.included(mod)
    mod.include ActiveModel::Model
    mod.include ActiveModel::Attributes
    mod.include ActiveModel::AttributeAssignment

    mod.include Attributes
    mod.include NestedAttributes
    mod.include UndefinedAttributes

    mod.include ExtraKeys

    mod.include Options
    mod.include AttributeAssignment

    mod.include Normalize

    mod.include TypeValidations
  end
end
