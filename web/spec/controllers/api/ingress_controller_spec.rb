# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::IngressController, type: :request do
  let!(:user) { create(:user) }

  describe 'POST /api/v1/ingress/heartbeat' do
    it 'returns a 200 status' do
      post api_heartbeat_path, as: :json

      expect(response).to have_http_status(:ok)
    end

    it 'returns a JSON response' do
      post api_heartbeat_path, as: :json
      json = response.parsed_body

      expect(json).to eq({ 'status' => 'ok' })
    end
  end
end
