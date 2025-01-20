# frozen_string_literal: true

module Comparisons::Dependency
  def self.compare(base, incoming)
    simple_compares = {
      version: "Version",
      repo_url: "Repo URL"
    }
    changes = Comparisons::Common.simple_comparisons(simple_compares, base:, incoming:)

    # TODO: add new modules in data.rb to compare the configs fields for each dependency
    config_changes = base.configs.map do |field, old_value|
      new_value = incoming.configs[field]
      next if new_value == old_value

      Comparisons::Change.new(field:, old_value:, new_value:)
    end

    changes + config_changes.compact
  end
end
