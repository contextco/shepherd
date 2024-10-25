# frozen_string_literal: true

# This module extends ActiveModel::Base.attribute method and allows creation of deeply nested form attributes.
# Usage:
#   class MyForm
#     attribute :main_foo do
#       attribute :bar, default: 10
#     end
#   end

#   form = MyForm.new
#   form.attributes #=> { 'main_foo' => { 'bar' => 10 }}
#   form.main_foo.bar = 20
#
# You can pass `multiple: true` to create an array of nested objects instead:
#
#   class MyForm
#     attribute :foos, multiple: true do
#       attribute :bar
#     end
#   end
#
#   form = MyForm.new
#   form.attributes #=> { 'foos' => [] }
#   form.foos.build.bar = 10
#   form.attributes #=> { 'foos' => [{ 'bar' => 10 }] }
#
# Nested attributes are ready to use with rails' `fields_for` as it defines `#{attribute}_attributes=` method to handle
# mass assignment. Note however that forms are not persistable - they will not generate id hidden field and reassigning
# multiple nested attributes will destroy and recreate all the nested forms.
#
# When creating a multiple attribute, you can override 'default_attributes' method to define attributes to be used as a
# function of index:
#   class MyForm
#     attribute :foos, multiple: true do
#       attribute :bar
#
#        def default_attributes(index)
#          { bar: index }
#        end
#     end
#   end

#   form = MyForm.new
#   form.attributes #=> { 'foos' => [] }
#   3.times { form.foos.build }
#   form.foos.pluck(:bar) #=> [0, 1, 2]

module FormObject
  module NestedAttributes
    def self.included(mod)
      mod.extend ClassMethods
    end

    def initialize(*)
      @nested_attributes = self.class.nested_attributes.transform_values do |opts|
        opts[:multiple] ? Multiple.new(opts[:type], **@options) : opts[:type].new({}, **@options)
      end
      super
    end

    def attributes(symbolize: false)
      nested = @nested_attributes.transform_values { |nested_form| nested_form.attributes(symbolize:) }
      nested.transform_keys!(&:to_s) unless symbolize
      super.merge(nested)
    end

    module ClassMethods
      def attribute(name, type = nil, multiple: false, validate: true, **, &block)
        return super(name, type, **) unless block
        raise ArgumentError, "Nested arguments with types are not yet supported" if type.present?

        type = Class.new do
          include FormObject

          def default_attributes(_index)
            {}
          end

          def self.prepopulate; end

          class_eval(&block)
        end

        const_set("#{name.to_s.singularize.classify}Form", type)

        nested_attributes[name] = { type:, multiple: }
        define_method(name) { @nested_attributes[name] }
        define_method("#{name}_attributes=") { |value| @nested_attributes[name].assign_attributes(value) }
        define_method("#{name}=") { |value| @nested_attributes[name].assign_attributes(value) }

        validates name, nested_attribute: true if validate
      end

      def nested_attributes
        @nested_attributes ||= {}
      end
    end
  end

  class Multiple
    attr_reader :errors

    def initialize(form_class, **options)
      @form_class = form_class
      @forms = @form_class.prepopulate || []
      @errors = ActiveModel::Errors.new(self)
      @options = options
    end

    def attributes(symbolize: false)
      @forms.map { |form| form.attributes(symbolize:) }
    end

    def build(params = {}, index: @forms.count)
      new_form = @form_class.new({}, **@options)
      new_form.assign_attributes(new_form.default_attributes(index))
      new_form.assign_attributes(params)
      @forms << new_form
    end

    def assign_attributes(attrs = {})
      @forms = []
      attrs = attrs.each_with_index.to_h { |element, index| [ index, element ] } if attrs.is_a?(Array)
      attrs.each_value do |element|
        build(element)
      end
    end

    def valid?
      @errors.clear
      return true if @forms.all? { |form| form.errors.empty? && form.valid? }

      @forms.each_with_index.map do |form, index|
        form.errors.objects.each do |error|
          errors.import(error, attribute: "#{index}.#{error.attribute}")
        end
      end

      false
    end

    def method_missing(name, ...)
      super unless @forms.respond_to?(name)

      @forms.public_send(name, ...)
    end

    def respond_to_missing?(name, private = false)
      @forms.respond_to?(name, private)
    end
  end

  class NestedAttributeValidator < ActiveModel::EachValidator
    def validate_each(form, attribute_name, value)
      return if value.valid?

      value.errors.objects.each do |error|
        form.errors.import(error, attribute: "#{attribute_name}.#{error.attribute}")
      end
    end
  end
end
