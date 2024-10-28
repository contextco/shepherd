# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HeartbeatController do
  let(:deployment) { create(:deployment) }

  describe 'heartbeat' do
    let(:request_message) { HeartbeatRequest.new(identity: { lifecycle_id: 'my-lifecycle', name: 'web' }) }

    subject(:heartbeat) { run_rpc(:Heartbeat, request_message, **authorization_options_for(deployment)) }

    it 'returns a HeartbeatResponse' do
      expect(heartbeat).to be_a(HeartbeatResponse)
    end

    it 'records a heartbeat' do
      expect { heartbeat }.to change { deployment.health_logs.count }.by(1)
    end

    it 'creates a container' do
      expect { heartbeat }.to change { deployment.containers.count }.by(1)
    end

    context 'when the container already exists' do
      before { deployment.containers.create!(name: 'web') }

      it 'does not create a new container' do
        expect { heartbeat }.not_to change { deployment.containers.reload.count }
      end

      it 'creates a health log' do
        expect { heartbeat }.to change { deployment.health_logs.count }.by(1)
      end
    end

    context 'when no auth header is provided' do
      subject(:heartbeat) { run_rpc(:Heartbeat, request_message) }

      it 'raises unauthenticated response' do
        expect { heartbeat }.to raise_rpc_error(GRPC::Unauthenticated)
      end
    end

    context 'when the bearer token is invalid' do
      subject(:heartbeat) { run_rpc(:Heartbeat, request_message, active_call_options: { metadata: { authorization: 'Bearer invalid' } }) }

      it 'raises unauthenticated response' do
        expect { heartbeat }.to raise_rpc_error(GRPC::Unauthenticated)
      end
    end

    context 'when the bearer token is malformed' do
      subject(:heartbeat) { run_rpc(:Heartbeat, request_message, active_call_options: { metadata: { authorization: 'invalid' } }) }

      it 'raises unauthenticated response' do
        expect { heartbeat }.to raise_rpc_error(GRPC::Unauthenticated)
      end
    end
  end
end
