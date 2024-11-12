# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project::ServiceController, type: :request do
  let(:project_service) { create(:project_service, team: user.team) }

  let(:user) { create(:user) }

  before { sign_in user }

  describe 'GET #show' do
    subject { get project_service_path(project_service) }

    it 'returns http success' do
      subject
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #new' do
    subject { get new_version_project_service_path(project_service.project_version) }

    it 'returns http success' do
      subject
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #edit' do
    subject { get edit_project_service_path(project_service) }

    it 'returns http success' do
      subject
      expect(response).to have_http_status(:success)
    end
  end
end



