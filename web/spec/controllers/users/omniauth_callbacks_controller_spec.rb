# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController do
  describe 'POST #google_oauth2' do
    let(:auth) { OmniAuth.config.mock_auth[:google_oauth2] }

    before do
      request.env['devise.mapping'] = Devise.mappings[:user]
      request.env['omniauth.auth'] = auth
    end

    it 'creates a new user' do
      expect { post :google_oauth2 }.to change(User, :count).by(1)
    end
  end
end
