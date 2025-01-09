# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AgentController do
  let(:project_subscriber) { create(:project_subscriber) }

  describe 'heartbeat' do
    let(:request_message) { HeartbeatRequest.new(identity: { lifecycle_id: 'my-lifecycle', name: 'web' }) }

    subject(:heartbeat) { run_rpc(:Heartbeat, request_message, **authorization_options_for(project_subscriber)) }

    it 'returns a HeartbeatResponse' do
      expect(heartbeat).to be_a(HeartbeatResponse)
    end

    it 'records a heartbeat' do
      expect { heartbeat }.to change { project_subscriber.heartbeat_logs.count }.by(1)
    end

    it 'creates a container' do
      expect { heartbeat }.to change { project_subscriber.agent_instances.count }.by(1)
    end

    context 'when the container already exists' do
      before { project_subscriber.agent_instances.create!(name: 'web', lifecycle_id: 'my-lifecycle') }

      it 'does not create a new container' do
        expect { heartbeat }.not_to change { project_subscriber.agent_instances.reload.count }
      end

      it 'creates a health log' do
        expect { heartbeat }.to change { project_subscriber.event_logs.count }.by(1)
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

  describe 'apply' do
    before do
      project_subscriber
    end

    context 'when there are no pending actions' do
      it 'returns an ApplyResponse with no action' do
        apply_response = run_rpc(:Apply, ApplyRequest.new, **authorization_options_for(project_subscriber))
        expect(apply_response.action).to be_nil
      end
    end

    context 'when there is a pending action' do
      let!(:action) { create(:apply_version_action, subscriber: project_subscriber) }

      let(:bucket) { double('Google::Cloud::Storage::Bucket') }
      let(:file) { double('Google::Cloud::Storage::File') }

      before do
        allow(GCSClient).to receive(:onprem_bucket).and_return(bucket)
        allow(bucket).to receive(:file).and_return(file)
        allow(file).to receive(:download).and_return(StringIO.new("some yaml"))
      end

      it 'returns an ApplyResponse with the action' do
        apply_response = run_rpc(:Apply, ApplyRequest.new, **authorization_options_for(project_subscriber))
        expect(apply_response).to eq(action.convert_to_proto)
      end

      it 'completes the action' do
        expect { run_rpc(:Apply, ApplyRequest.new, **authorization_options_for(project_subscriber)) }.to change { action.reload.status }.from('pending').to('completed')
      end
    end
  end
end
