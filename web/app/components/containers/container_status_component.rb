# frozen_string_literal: true

class Containers::ContainerStatusComponent < ApplicationComponent
  attribute :name
  attribute :containers

  DAYS = 90

  def containers_statuses
    @containers_statuses ||= containers.map { |container| ::ContainerStatus.new(container).generate_status_per_day }
  end

  def group_status_for_day(day)
    # this feels like it should be its own abstraction...
    all_container_status = containers_statuses.map { |container_status| container_status[day][:status] }
    date = containers_statuses.first[day][:date]
    uptime_minutes = containers_statuses.sum { |container_status| container_status[day][:uptime_minutes] }
    downtime_minutes = containers_statuses.sum { |container_status| container_status[day][:downtime_minutes] }
    total_minutes = uptime_minutes + downtime_minutes
    uptime_percentage = total_minutes.zero? ? 0 : ((uptime_minutes / (uptime_minutes + downtime_minutes).to_f) * 100).round(2)

    return { status: :offline, date:, uptime_minutes:, downtime_minutes:, uptime_percentage: } if all_container_status.include?(:offline)
    return { status: :degraded, date:, uptime_minutes:, downtime_minutes:, uptime_percentage: } if all_container_status.include?(:degraded)
    return { status: :no_data, date:, uptime_minutes:, downtime_minutes:, uptime_percentage: } if all_container_status.all?(:no_data)

    { status: :online, date:, uptime_minutes:, downtime_minutes:, uptime_percentage: }
  end

  def group_status_bars
    @group_status_bars ||= DAYS.times.map { |day| group_status_for_day(day) }.reverse
  end

  def uptime_percentage
    total_operational = group_status_bars.count { |day| day[:status] == :online }
    ((total_operational.to_f / DAYS) * 100).round(2)
  end

  def current_status
    # TODO: implement this correctly and refactor container to enum to be consistent
    return @current_status if defined?(@current_status)
    return @current_status = :offline if containers.all?(&:unhealthy?)
    return @current_status = :degraded if containers.any?(&:unhealthy?)

    @current_status = :online
  end

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
