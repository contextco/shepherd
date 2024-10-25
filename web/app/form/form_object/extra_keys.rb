# frozen_string_literal: true

# This module allows configuring the form object's behaviour when confronted with unknown key using `extra_keys` option.
# Allowed options are:
#   * raise - (default) raises UnknownAttributes with a list of unknown attributes
#   * ignore - ignores all the unknown keys
#   * error - report unknown keys with validation errors (marks form as invalid)

module FormObject
  class UnknownAttributesError < StandardError
    attr_reader :base, :attributes

    def initialize(base, attributes)
      @base = base
      @attributes = attributes

      attribute_list = attributes.map { |attr| "`#{attr}`" }.to_sentence
      super("Unknown #{'attribute'.pluralize(@attributes.count)} for #{base.class.name}: #{attribute_list}")
    end
  end

  module ExtraKeys
    extend ActiveSupport::Concern
    OPTIONS = {
      raise: ->(extras, _paarams) { raise UnknownAttributesError.new(self, extras) if extras.any? },
      error: ->(extras, _params) { @extra_keys = extras },
      remove: ->(extras, params) { extras.each { |key| params.delete(key) } },
      ignore: ->(_, _) { }
    }.freeze

    included do
      validate :check_extra_keys
    end

    def initialize(*, **)
      @options[:extra_keys] ||= :raise
      unless OPTIONS.keys.include?(@options[:extra_keys])
        formatted_options = OPTIONS.keys.map { |key| "`#{key.inspect}`" }.to_sentence
        raise ArgumentError, "invalid value for `extra_keys` option. Allowed values are: #{formatted_options}"
      end
      super
    end

    def assign_attributes(params)
      params = params&.stringify_keys || {}
      extras = params.slice!(*self.class.expected_attributes)
      handler = OPTIONS[@options[:extra_keys]]
      instance_exec(extras.keys, params, &handler)
      super
    end

    def check_extra_keys
      return unless @options[:extra_keys] == :error && @extra_keys&.any?

      @extra_keys.each { |extra| errors.add(extra, "unknown key") }
    end

    module ClassMethods
      def expected_attributes
        [
          attribute_names,
          nested_attributes.keys.map(&:to_s),
          nested_attributes.keys.map { |nested| "#{nested}_attributes" }
        ].flatten
      end
    end
  end
end
