# frozen_string_literal: true

class ContainerStatus
  DAYS = 90
  MINUTES_PER_DAY = 1440

  HEARTBEAT_GAP_THRESHOLD = 6.minutes

  OFFLINE_THRESHOLD = 2.hours
  DEGRADED_THRESHOLD = 10.minutes

  def initialize(container)
    @container = container
  end

  def generate_status_per_day
    result = initialize_days_hash
    first_heartbeat = heartbeat_logs.order(:created_at).first&.created_at

    mark_inactive_days(result, first_heartbeat || Time.zone.now + 1.day) # mark all days before the first heartbeat as no data
    return result if heartbeat_logs.none?

    process_gaps(find_gaps, result, first_heartbeat)
    calculate_daily_status(result)

    result
  end

  private

  def initialize_days_hash
    (0..DAYS).each_with_object({}) do |days_ago, hash|
      hash[days_ago] = {
        lifecycle_id: @container.lifecycle_id,
        status: :online,
        date: days_ago.days.ago.to_date,
        downtime_minutes: 0,
        uptime_minutes: MINUTES_PER_DAY,
        uptime_percentage: 0
      }
    end
  end

  def calculate_daily_status(result)
    result.each do |_, day_data|
      next if day_data[:status] == :no_data
      day_data[:status] = determine_status(day_data[:downtime_minutes])
    end
  end

  def determine_status(downtime_minutes)
    return :offline if downtime_minutes >= OFFLINE_THRESHOLD / 60
    return :degraded if downtime_minutes >= DEGRADED_THRESHOLD / 60

    :online
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
      process_gap(gap, result, first_heartbeat)
    end
  end

  def process_gap(gap, result, first_heartbeat)
    (gap[:start_time].to_date..gap[:end_time].to_date).each do |date|
      days_ago = (Time.zone.today - date).to_i
      next if days_ago > DAYS || days_ago < 0

      result[days_ago][:downtime_minutes] += calculate_gap_downtime(gap, date)
      result[days_ago][:uptime_minutes] = calculate_day_uptime(date, result[days_ago][:downtime_minutes], first_heartbeat)
      result[days_ago][:uptime_percentage] = calculate_percentage(result[days_ago][:uptime_minutes], result[days_ago][:downtime_minutes])
    end
  end

  def calculate_gap_downtime(gap, date)
    gap_start = [ gap[:start_time], date.beginning_of_day ].max
    gap_end = [ gap[:end_time], date.end_of_day ].min
    ((gap_end - gap_start) / 60).round
  end

  def calculate_day_uptime(date, downtime, first_heartbeat)
    return [ minutes_passed_today - downtime, 0 ].max if date == Time.zone.today
    return calculate_first_day_uptime(first_heartbeat, downtime) if date == first_heartbeat.to_date

    [ MINUTES_PER_DAY - downtime, 0 ].max
  end

  def calculate_percentage(uptime, downtime)
    total = uptime + downtime
    return 0 if total.zero?

    (uptime / total.to_f * 100).round(2)
  end

  def calculate_first_day_uptime(first_heartbeat, downtime)
    total_minutes = ((first_heartbeat.end_of_day - first_heartbeat) / 60).to_i
    [ total_minutes - downtime, 0 ].max
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

  def minutes_passed_today
    (Time.current.seconds_since_midnight / 60).to_i
  end

  def heartbeat_logs
    @heartbeat_logs ||= @container.heartbeat_logs
  end
end
