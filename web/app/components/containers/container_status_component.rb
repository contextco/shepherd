# frozen_string_literal: true

class Containers::ContainerStatusComponent < ApplicationComponent
  attribute :name
  attribute :containers

  DAYS = 90

  def group_status
    @group_status ||= ::ContainerStatus::GroupHeartbeat.from(containers:, days: DAYS)
  end

  def status_text(status)
    return "Offline" if status == :offline
    return "Degraded" if status == :degraded
    return "Online" if status == :online

    "No Data"
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
