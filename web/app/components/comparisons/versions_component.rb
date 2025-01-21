# frozen_string_literal: true

class Comparisons::VersionsComponent < ApplicationComponent
  attribute :version_comparison

  def icon(comparison)
    case comparison.status
    when :added
      "plus-circle"
    when :modified
      "pencil-square"
    when :removed
      "minus-circle"
    else
      "question-circle"
    end
  end

  def icon_classes(comparison)
    default = "size-4 stroke-2 mb-1"

    case comparison.status
    when :added
      "text-green-500 #{default}"
    when :modified
      "text-stone-500 #{default}"
    when :removed
      "text-red-500 #{default}"
    else
      "text-gray-500 #{default}"
    end
  end

  def change_text_classes(change)
    default = "px-1 py-0.5"

    return "bg-green-100 #{default}" if change.added?
    return "bg-red-200 #{default}" if change.removed?

    "bg-stone-100 #{default}"
  end
end
