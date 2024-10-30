# frozen_string_literal: true

class Containers::IndividualContainerStatusComponent < ApplicationComponent
  attribute :name
  attribute :status_bars

  DAYS = 90

  def status_text(status)
    return "Offline" if status == :offline
    return "Degraded" if status == :degraded
    return "Online" if status == :online

    "No Data"
  end

  def bg_classes(status)
    case status
    when :offline
      "bg-red-500"
    when :degraded
      "bg-yellow-500"
    when :online
      "bg-green-500"
    else
      "bg-gray-500"
    end
  end

  def text_classes(status)
    case status
    when :offline
      "text-red-500"
    when :degraded
      "text-yellow-500"
    when :online
      "text-green-500"
    else
      "text-gray-500"
    end
  end
end
