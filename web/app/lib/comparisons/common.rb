# frozen_string_literal: true

module Comparisons::Common
  class << self
    # Compares attributes between two objects and returns a list of changes.
    #
    # @param attrs_hash [Hash] A hash where keys are attribute names and values are display names.
    # @param base [Object] The base object to compare.
    # @param incoming [Object] The incoming object to compare.
    # @return [Array<Comparisons::Change>] An array of changes, each represented by a Comparisons::Change object.
    def simple_comparisons(attrs_hash, base:, incoming:)
      attrs_hash.map do |attr, display_name|
        simple_compare(attr, display_name, base, incoming)
      end.compact
    end

    # Compares arrays of hashes and returns a list of changes.
    #
    # @param key_field [String] The key field to identify unique objects in the arrays.
    # @param value_field [String] The value field to compare between the objects.
    # @param base [Array<Hash>] The base array of hashes to compare.
    # @param incoming [Array<Hash>] The incoming array of hashes to compare.
    # @param display_field [String] The display name for the field being compared.
    # @return [Array<Comparisons::Change>] An array of changes, each represented by a Comparisons::Change object.
    def array_hash_comparisons(key_field:, value_field:, base:, incoming:, display_field:)
      (base + incoming)
        .map { |obj| obj[key_field] }
        .uniq
        .map do |key|
        old_value = base.find { |obj| obj[key_field] == key }&.dig(value_field)
        new_value = incoming.find { |obj| obj[key_field] == key }&.dig(value_field)
        next if old_value == new_value

        Comparisons::Change.new(field: "#{display_field} #{key}", old_value:, new_value:)
      end.compact
    end

    # Compares arrays and returns a list of changes.
    #
    # @param base [Array] The base array to compare.
    # @param incoming [Array] The incoming array to compare.
    # @param display_field [String] The display name for the field being compared.
    # @return [Array<Comparisons::Change>] An array of changes, each represented by a Comparisons::Change object.
    def array_comparisons(base:, incoming:, display_field:)
      (base + incoming)
        .uniq
        .map do |value|
        old_value = base.include?(value) ? value : nil
        new_value = incoming.include?(value) ? value : nil
        next if old_value.present? && new_value.present?

        Comparisons::Change.new(field: display_field, old_value:, new_value:)
      end.compact
    end

    private

    def simple_compare(attribute, display_name, base, incoming)
      old_value = base.public_send(attribute)
      new_value = incoming.public_send(attribute)

      return nil if old_value == new_value

      Comparisons::Change.new(field: display_name, old_value:, new_value:)
    end
  end
end
