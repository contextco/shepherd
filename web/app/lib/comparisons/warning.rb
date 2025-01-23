# frozen_string_literal: true

class Comparisons::Warning
  CHANGE_RULES = {
    "Port" => {
      message: "One or more ports have been modified or removed. This may impact the clients deployment if they rely on these ports being open.",
      conditions: [ :modified?, :removed? ]
    },
    "Secret" => {
      message: "One or more secrets have been modified or added. The client will have manually update their secrets. Consider instead making this change in the application layer instead.",
      conditions: [ :modified?, :added? ]
    }
  }.freeze

  def initialize(object_comparisons)
    @object_comparisons = object_comparisons
    @all_changes = extract_all_changes
  end

  def warnings
    CHANGE_RULES.each_with_object([]) do |(field, rule), warns|
      field_changes = changes_for_field(field)
      warns << rule[:message] if rule_conditions_met?(field_changes, rule[:conditions])
    end
  end

  private

  def extract_all_changes
    @object_comparisons
      .filter(&:modified?)
      .map(&:changes)
      .flatten
  end

  def changes_for_field(field_name)
    @all_changes.filter { |change| change.field == field_name }
  end

  def rule_conditions_met?(changes, conditions)
    conditions.any? do |condition|
      changes.any? { |change| change.public_send(condition) }
    end
  end
end
