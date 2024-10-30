# # frozen_string_literal: true

class ContainerStatus
  DAYS = 90
  THRESHOLD = 6.minutes
  OFFLINE_THRESHOLD = 2.hour
  DEGRADED_THRESHOLD = 10.minutes

  attr_reader :container

  def initialize(container)
    @container = container
  end

  def generate_status_per_day
    # Initialize result for last 90 days
    result = (0..DAYS).each_with_object({}) do |days_ago, hash|
      hash[days_ago] = {
        status: :no_data,
        date: days_ago.days.ago.to_date,
        downtime_minutes: 0,
        uptime_minutes: 0
      }
    end

    first_heartbeat = heartbeat_logs.first&.created_at
    return result if heartbeat_logs.none? || first_heartbeat.nil?

    process_gaps(find_gaps, result)

    # Calculate status for each day based on downtime
    result.each do |_, day_data|
      day_data[:status] = determine_status(day_data[:downtime_minutes])
    end

    result
  end

  def find_gaps
    last_timestamp = nil
    gaps = []

    heartbeat_logs
      .where("created_at > ?", DAYS.days.ago)
      .group_by_minute(:created_at, n: 5)
      .count
      .each do |timestamp, _|
      if last_timestamp && (timestamp - last_timestamp) > THRESHOLD
        gaps << { start_time: last_timestamp, end_time: timestamp }
      end
      last_timestamp = timestamp
    end

    gaps
  end

  def process_gaps(gaps, result)
    gaps.each do |gap|
      # Handle gaps that span multiple days
      (gap[:start_time].to_date..gap[:end_time].to_date).each do |date|
        days_ago = (Time.zone.today - date).to_i
        next if days_ago > DAYS || days_ago < 0

        # Calculate downtime for this specific day
        day_start = date.beginning_of_day
        day_end = date.end_of_day
        gap_start = [ gap[:start_time], day_start ].max
        gap_end = [ gap[:end_time], day_end ].min

        downtime_minutes = ((gap_end - gap_start) / 60).round
        result[days_ago][:downtime_minutes] += downtime_minutes

        # Calculate uptime (assuming 24 hours per day minus downtime)
        result[days_ago][:uptime_minutes] = 1440 - result[days_ago][:downtime_minutes]
      end
    end
  end

  def determine_status(downtime_minutes)
    return :offline if downtime_minutes >= OFFLINE_THRESHOLD / 60
    return :degraded if downtime_minutes >= DEGRADED_THRESHOLD / 60

    :online
  end

  def heartbeat_logs
    @heartbeat_logs ||= container.heartbeat_logs
  end
end
