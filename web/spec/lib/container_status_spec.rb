# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContainerStatus do
  subject { described_class.new(container) }

  let(:container) { create(:container) }

  describe '#generate_status_per_day' do
    context 'when no heartbeat logs exist' do
      it 'returns a hash with 90 elements' do
        expect(subject.generate_status_per_day.size).to eq(91)
      end

      it 'returns a hash with all elements having status :no_data' do
        expect(subject.generate_status_per_day.values.all? { |v| v[:status] == :no_data }).to be true
      end

      it 'returns a hash with all elements having downtime_minutes and uptime_minutes as 0' do
        expect(subject.generate_status_per_day.values.all? { |v| v[:downtime_minutes] == 0 && v[:uptime_minutes] == 0 }).to be true
      end
    end

    context 'when some heartbeat logs exist' do
      # heart beat for every 5 minutes 2 days ago
      let!(:event_logs_2_days_ago) do
        (0..288).each do |i|
          create(:event_log, event_type: :heartbeat, container:, created_at: 2.day.ago.beginning_of_day + i * 5.minutes)
        end
      end

      # heart beat for every 5 minutes besides 1 hour 1 day ago
      let!(:event_logs_1_day_ago) do
        (0..276).each do |i|
          create(:event_log, event_type: :heartbeat, container:, created_at: 1.day.ago.beginning_of_day + i * 5.minutes)
        end
      end

      it 'returns a hash with 91 elements' do
        expect(subject.generate_status_per_day.size).to eq(91)
      end

      it 'returns a hash with the last 88 elements having status :no_data' do
        expect(subject.generate_status_per_day.values.last(88).all? { |v| v[:status] == :no_data }).to be true
      end

      it 'returns a hash with element 2 days ago having status :online and uptime 1440' do
        expect(subject.generate_status_per_day[2][:status]).to eq(:online)
        expect(subject.generate_status_per_day[2][:uptime_minutes]).to eq(1440)
        expect(subject.generate_status_per_day[2][:downtime_minutes]).to eq(0)
      end

      it 'returns a hash with element 1 day ago having status :degraded and downtime 60' do
        expect(subject.generate_status_per_day[1][:status]).to eq(:degraded)
        expect(subject.generate_status_per_day[1][:downtime_minutes]).to eq(60)
      end

      it 'returns a hash with element today having status :offline' do
        expect(subject.generate_status_per_day[0][:status]).to eq(:offline)
        # offline time depends on current time
        expect(subject.generate_status_per_day[0][:downtime_minutes]).to be_within(5.minute).of((Time.zone.now - Time.zone.now.beginning_of_day)/60)
      end
    end
  end
end
