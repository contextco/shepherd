# frozen_string_literal: true

# This module makes it possible for us to detect if the given attribute has been at all included in the payload or not.
# Usage:
#     class Form
#       include FormObject
#       attribute :a
#       attribute :b
#       attribute :c, default: 1
#     end
#
#     form = Form.new(a: 1)
#     form.b                        #=> nil
#     form.c                        #=> 1 - default values are preserved
#     form.attribute_defined?(:a)   #=> true
#     form.attribute_defined?(:b)   #=> false
#     form.attribute_defined?(:c)   #=> false - default value does not affect attribute definition
#     form.b_defined?               #=> false

#     form.b = nil
#     form.b_defined?               #=> true - explicit assignment marks attribute as defined

module FormObject
  module UndefinedAttributes
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    def initialize(params = {})
      super
      @attributes = AttributeSetWrapper.new(@attributes)
      # At this point, the initial params are already assigned so we need to populate written_attributes.
      # One alternative would be to re-assign attributes, but this might trigger custom setters twice. Another option
      # would be to inject this module between initial @attribute definition and assignment, however module inclusion
      # ordering would be very fragile.
      @attributes.written_attributes.merge(params.keys.map(&:to_s))
    end

    def attribute_defined?(attr_name)
      @attributes.attribute_written?(attr_name)
    end

    module ClassMethods
      def attribute(name, *, **opts, &)
        super

        mod = Module.new do
          define_method "#{name}_defined?" do
            attribute_defined?(name)
          end
        end

        include mod
      end
    end

    class AttributeSetWrapper < SimpleDelegator
      def written_attributes
        @written_attributes ||= Set.new
      end

      def write_from_user(name, value)
        super
        written_attributes << name.to_s
      end

      def attribute_written?(name)
        written_attributes.include?(name.to_s)
      end
    end

    class DefinedValidator < ActiveModel::EachValidator
      def validate_each(form, attribute, _value)
        form.errors.add(attribute, "is missing") unless form.attribute_defined?(attribute)
      end
    end

    class UndefinedValidator < ActiveModel::EachValidator
      def validate_each(form, attribute, _value)
        form.errors.add(attribute, @options.fetch(:message, "is not allowed")) if form.attribute_defined?(attribute)
      end
    end
  end
end
