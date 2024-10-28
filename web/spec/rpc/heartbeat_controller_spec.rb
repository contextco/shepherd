# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HeartbeatController do
  let(:deployment) { create(:deployment) }

  describe 'heartbeat' do
    let(:request_message) { HeartbeatRequest.new }

    subject(:heartbeat) { run_rpc(:Heartbeat, request_message, **authorization_options_for(deployment)) }

    it 'returns a HeartbeatResponse' do
      expect(heartbeat).to be_a(HeartbeatResponse)
    end
  end
end
