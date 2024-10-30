# frozen_string_literal: true

class Containers::ContainerStatusComponent < ApplicationComponent
  attribute :name
  attribute :containers

  DAYS = 90

  def status_for_day(day)
    containers.any? { |container| container.unhealthy? } ? "operational" : "unresponsive"
  end

  def status_bars
    DAYS.times.map do |day|
      status = status_for_day(day)
      { date: DAYS.days.ago.to_date + day.days, status: }
    end.reverse
  end

  def uptime_percentage
    total_operational = status_bars.count { |day| day[:status] == "operational" }
    ((total_operational.to_f / DAYS) * 100).round(2)
  end
end
