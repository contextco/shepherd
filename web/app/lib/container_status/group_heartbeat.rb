# frozen_string_literal: true

module ContainerStatus
  GroupHeartbeat = Struct.new(
    :containers,
    :days,
    :constituent_stats,
    :group_stats,
    keyword_init: true
  ) do

    def current_status
      # TODO: implement this correctly and refactor container to enum to be consistent
      return @current_status if defined?(@current_status)
      return @current_status = :offline if containers.all?(&:unhealthy?)
      return @current_status = :degraded if containers.any?(&:unhealthy?)

      @current_status = :online
    end

    def uptime_percentage
      return @uptime_percentage if defined?(@uptime_percentage)

      total_operational = group_stats.count { |day_stats| day_stats[:status] == :online }

      @uptime_percentage = ((total_operational.to_f / days) * 100).round(2)
    end

    class << self
      def from(containers:, days: 90)
        constituent_stats = stats(containers, days)

        new(
          containers:,
          days:,
          constituent_stats:,
          group_stats: group_stats(constituent_stats, days)
        )
      end

      private

      def stats(containers, _)
        containers.map { |container| HeartbeatStats.new(container).generate_status_per_day }
      end

      def group_stats(constituent_stats, days)
        days.times.map { |day| group_status_for_day(constituent_stats, day) }.reverse
      end

      def group_status_for_day(constituent_stats, day)
        all_container_status = constituent_stats.map { |container_status| container_status[day][:status] }
        date = constituent_stats.first[day][:date]
        uptime_minutes = constituent_stats.sum { |container_status| container_status[day][:uptime_minutes] }
        downtime_minutes = constituent_stats.sum { |container_status| container_status[day][:downtime_minutes] }
        total_minutes = uptime_minutes + downtime_minutes
        uptime_percentage = total_minutes.zero? ? 0 : ((uptime_minutes / (uptime_minutes + downtime_minutes).to_f) * 100).round(2)

        return { status: :offline, date:, uptime_minutes:, downtime_minutes:, uptime_percentage: } if all_container_status.include?(:offline)
        return { status: :degraded, date:, uptime_minutes:, downtime_minutes:, uptime_percentage: } if all_container_status.include?(:degraded)
        return { status: :no_data, date:, uptime_minutes:, downtime_minutes:, uptime_percentage: } if all_container_status.all?(:no_data)

        { status: :online, date:, uptime_minutes:, downtime_minutes:, uptime_percentage: }
      end
    end
  end
end
