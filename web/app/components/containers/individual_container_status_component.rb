# frozen_string_literal: true

class Containers::IndividualContainerStatusComponent < ApplicationComponent
  attribute :status_bars
  attribute :container

  DAYS = 90

  def current_status
    return @current_status if defined?(@current_status)
    return @current_status = :offline unless container&.healthy?

    @current_status = :online
  end

  def status_text(status)
    return "Offline" if status == :offline
    return "Degraded" if status == :degraded
    return "Online" if status == :online

    "No Data"
  end

  def uptime_percentage
    # TODO: create a proper struct output from container status which containers metadata like this
    with_data_bars = status_bars.filter { |bar| bar[:status] != :no_data }
    return 0 if with_data_bars.empty?

    percentage = with_data_bars.sum { |bar| bar[:uptime_percentage] } / with_data_bars.size

    percentage.round(1)
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
