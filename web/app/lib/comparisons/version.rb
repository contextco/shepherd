# frozen_string_literal: true

module Comparisons::Version
  VersionComparison = Struct.new(
    :base_version,
    :incoming_version,
    :comparisons,
    keyword_init: true
  ) do
    class << self
      def from(base_version, incoming_version)
        comparisons = [
          compare_objects(base_version.services, incoming_version.services, type: :service),
          compare_objects(base_version.dependencies, incoming_version.dependencies, type: :dependency)
        ].flatten.compact

        new(base_version:, incoming_version:, comparisons:)
      end

      private

      def compare_objects(base_objects, incoming_objects, type:)
        base_objects = base_objects.index_by(&:name)
        incoming_objects = incoming_objects.index_by(&:name)
        all_service_names = (base_objects.keys + incoming_objects.keys).uniq

        all_service_names.map do |name|
          base_object = base_objects[name]
          incoming_object = incoming_objects[name]

          # default to modified, if not added or removed and not actually modified. we exit early.
          status = :modified
          changes = []

          status = :added if base_object.nil?
          status = :removed if incoming_object.nil?
          changes = base_object.compare(incoming_object) if status == :modified
          next if changes.empty? && status == :modified

          Comparisons::ObjectComparison.new(name:, type:, status:, changes:)
        end
      end
    end

    def has_changes?
      comparisons.any?
    end
  end
end
