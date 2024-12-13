# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AgentInstance do
  describe 'after_find' do
    context 'when the agent_instance is initially healthy' do
      let(:agent_instance) { create(:agent_instance, status: :healthy) }
      let!(:event_log) { create(:event_log, agent_instance:, created_at: 10.minutes.ago) }

      it 'calls #update_status' do
        expect_any_instance_of(AgentInstance).to receive(:update_status)
        AgentInstance.find(agent_instance.id)
      end

      it 'updates status to unresponsive' do
        expect(agent_instance.reload.status).to eq 'unresponsive'
      end

      context 'when last heartbeat is within timeout' do
        let!(:event_log) { create(:event_log, agent_instance:, created_at: 4.minutes.ago) }

        it 'does not update status' do
          expect(agent_instance.reload.status).to eq 'healthy'
        end
      end
    end

    context 'when the container is initially unresponsive' do
      let(:agent_instance) { create(:agent_instance, status: :unresponsive) }
      let!(:event_log) { create(:event_log, agent_instance:, created_at: 10.minutes.ago) }

      it 'calls #update_status' do
        expect_any_instance_of(AgentInstance).to receive(:update_status)
        AgentInstance.find(agent_instance.id)
      end

      it 'does not update status' do
        expect(agent_instance.reload.status).to eq 'unresponsive'
      end

      context 'when last heartbeat is within timeout' do
        let!(:event_log) { create(:event_log, agent_instance:, created_at: 4.minutes.ago) }

        it 'updates status to healthy' do
          expect(agent_instance.reload.status).to eq 'healthy'
        end
      end
    end
  end
end
