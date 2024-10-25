# frozen_string_literal: true

module FormObject::TypeValidations
  extend ActiveSupport::Concern

  class InvalidTypeAssigned < StandardError; end

  class_methods do
    def attribute(attribute, type = nil, **options)
      validate_type(attribute, options[:expect_type]) if options[:expect_type]
      super
    end

    def validate_type(attribute, expect_type)
      define_method "#{attribute}=" do |value|
        errors.add(attribute, "must be a #{expect_type} type, instead found #{value}") unless value.is_a?(expect_type)

        super(value)
      end
    end
  end
end
