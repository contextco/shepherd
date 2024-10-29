# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Container do
  describe 'after_find' do
    context 'when the container is initially healthy' do
      let(:container) { create(:container, status: :healthy) }
      let!(:event_log) { create(:event_log, container:, created_at: 10.minutes.ago) }

      it 'calls #update_status' do
        expect_any_instance_of(Container).to receive(:update_status)
        Container.find(container.id)
      end

      it 'updates status to unresponsive' do
        expect(container.reload.status).to eq 'unresponsive'
      end

      context 'when last heartbeat is within timeout' do
        let!(:event_log) { create(:event_log, container:, created_at: 4.minutes.ago) }

        it 'does not update status' do
          expect(container.reload.status).to eq 'healthy'
        end
      end
    end

    context 'when the container is initially unresponsive' do
      let(:container) { create(:container, status: :unresponsive) }
      let!(:event_log) { create(:event_log, container:, created_at: 10.minutes.ago) }

      it 'calls #update_status' do
        expect_any_instance_of(Container).to receive(:update_status)
        Container.find(container.id)
      end

      it 'does not update status' do
        expect(container.reload.status).to eq 'unresponsive'
      end

      context 'when last heartbeat is within timeout' do
        let!(:event_log) { create(:event_log, container:, created_at: 4.minutes.ago) }

        it 'updates status to healthy' do
          expect(container.reload.status).to eq 'healthy'
        end
      end
    end
  end
end
