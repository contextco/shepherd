# frozen_string_literal: true

module Comparisons
  # Represents a change in a field of an object.
  #
  # @!attribute [r] field
  #   @return [String] the name of the field that changed
  # @!attribute [r] old_value
  #   @return [Object] the old value of the field
  # @!attribute [r] new_value
  #   @return [Object] the new value of the field
  Change = Struct.new(:field, :old_value, :new_value, keyword_init: true)

  # Represents a comparison of an object (service or dependency) between two versions.
  #
  # @!attribute [r] name
  #   @return [String] the name of the object being compared
  # @!attribute [r] type
  #   @return [Symbol] the type of the object (:service or :dependency)
  # @!attribute [r] status
  #   @return [Symbol] the status of the object (:added, :modified, or :removed)
  # @!attribute [r] changes
  #   @return [Array<Change>] the list of changes for the object
  ObjectComparison = Struct.new(
    :name,
    :type,
    :status,
    :changes,
    keyword_init: true
  ) do
    # Checks if the object is a dependency.
    # @return [Boolean] true if the object is a dependency, false otherwise
    def dependency?
      type == :dependency
    end

    # Checks if the object is a service.
    # @return [Boolean] true if the object is a service, false otherwise
    def service?
      type == :service
    end

    # Checks if the object is modified.
    # @return [Boolean] true if the object is modified, false otherwise
    def modified?
      status == :modified
    end

    # Checks if the object is added.
    # @return [Boolean] true if the object is added, false otherwise
    def added?
      status == :added
    end

    # Checks if the object is removed.
    # @return [Boolean] true if the object is removed, false otherwise
    def removed?
      status == :removed
    end
  end
end
