# frozen_string_literal: true

class ContainerStatus
  DAYS = 90
  HEARTBEAT_GAP_THRESHOLD = 6.minutes
  OFFLINE_THRESHOLD = 2.hours
  DEGRADED_THRESHOLD = 10.minutes

  def initialize(container)
    @container = container
  end

  def generate_status_per_day
    # Initialise result for last 90 days (91 days total including today)
    result = (0..DAYS).each_with_object({}) do |days_ago, hash|
      hash[days_ago] = {
        status: :online,
        date: days_ago.days.ago.to_date,
        downtime_minutes: 0,
        uptime_minutes: 1440
      }
    end

    first_heartbeat = heartbeat_logs.order(:created_at).first&.created_at
    mark_inactive_days(result, first_heartbeat || Time.zone.now + 1.day) # mark all days before the first heartbeat as no data

    return result if heartbeat_logs.none?

    # Process any gaps in the data
    process_gaps(find_gaps, result, first_heartbeat)

    # Calculate status for each day based on downtime
    result.each do |_, day_data|
      next if day_data[:status] == :no_data
      day_data[:status] = determine_status(day_data[:downtime_minutes])
    end

    result
  end

  def find_gaps
    timestamps = heartbeat_logs
      .where("created_at > ?", DAYS.days.ago)
      .group_by_minute(:created_at, n: 5).count.keys

    gaps = timestamps.each_cons(2)
      .filter_map { |t1, t2| { start_time: t1, end_time: t2 } if t2 - t1 > HEARTBEAT_GAP_THRESHOLD }

    # edge case where there is a gap at the end of the logs and now
    if timestamps.any? && (Time.zone.now - timestamps.last) > HEARTBEAT_GAP_THRESHOLD
      gaps << { start_time: timestamps.last, end_time: Time.zone.now }
    end

    gaps
  end

  def process_gaps(gaps, result, first_heartbeat)
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

        if date == Time.zone.today
          time_passed_today_minutes = (Time.current.seconds_since_midnight / 60).to_i
          result[days_ago][:uptime_minutes] = [ time_passed_today_minutes - result[days_ago][:downtime_minutes] ].max
          next
        end

        # if date is the first day we see a heartbeat, calculate uptime for the day
        if date == first_heartbeat.to_date
          total_time_for_day_since_first_heartbeat = ((first_heartbeat.end_of_day - first_heartbeat) / 60).to_i
          # downtime can be up to 5 minutes off which can lead to small negative values
          result[days_ago][:uptime_minutes] = [ total_time_for_day_since_first_heartbeat - result[days_ago][:downtime_minutes], 0 ].max
          next
        end

        result[days_ago][:uptime_minutes] = 1440 - result[days_ago][:downtime_minutes]
      end
    end
  end

  def mark_inactive_days(result, first_heartbeat)
    # mark all days before the first heartbeat as no data
    first_date = first_heartbeat.to_date
    days_since_first = (Time.zone.today - first_date).to_i
    return if days_since_first > DAYS

    (DAYS.days.ago.to_date..first_date - 1.day).each do |date|
      days_ago = (Time.zone.today - date).to_i
      result[days_ago].merge!(status: :no_data, uptime_minutes: 0)
    end
  end

  def determine_status(downtime_minutes)
    return :offline if downtime_minutes >= OFFLINE_THRESHOLD / 60
    return :degraded if downtime_minutes >= DEGRADED_THRESHOLD / 60

    :online
  end

  def heartbeat_logs
    @heartbeat_logs ||= @container.heartbeat_logs
  end
end
