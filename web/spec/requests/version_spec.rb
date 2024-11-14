# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project::VersionController, type: :request do
  let(:project_version) { create(:project_version, team: user.team, version: '0.0.1') }

  let(:user) { create(:user) }

  before { sign_in user }

  describe 'GET #show' do
    subject { get version_path(project_version) }

    it 'returns http success' do
      subject
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #new' do
    subject { get new_project_version_path(project_version.project) }

    it 'returns http success' do
      subject
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #edit' do
    subject { get edit_version_path(project_version) }

    it 'returns http success' do
      subject
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #create' do
    subject { post project_version_index_path(project_version.project), params: { project_version: { project_id: project_version.project_id, version: '1.0.0' } } }

    it 'creates a new project version' do
      project_version
      expect { subject }.to change(ProjectVersion, :count).by(1)
    end

    it 'redirects to the new project version' do
      subject
      expect(response).to redirect_to(version_path(project_version.reload.next_version))
    end

    it 'creates a new project version with the correct version number' do
      subject
      expect(project_version.next_version.version).to eq('1.0.0')
    end
  end
end
