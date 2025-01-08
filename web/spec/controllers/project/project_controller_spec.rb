# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project::ProjectController, type: :controller do
  let(:team) { create(:team) }
  let(:user) { create(:user, team:) }

  describe 'POST #create' do
    before do
      sign_in user
    end

    context 'when the project is created successfully' do
      subject { post :create, params: { name: 'test', team_id: team.id, description: 'test', agent: 'full' } }

      it 'creates a new project' do
        subject
        expect(response).to redirect_to(version_path(team.projects.first.latest_project_version))
      end

      it 'creates a new project version' do
        subject
        expect(team.projects.first.project_versions.count).to eq(1)
      end

      it 'creates a project version with the correct attributes' do
        subject
        expect(team.projects.first.latest_project_version.attributes).to include('description' => 'test', 'agent' => 'full')
      end

      it 'does not call publish! on the project version' do
        expect_any_instance_of(ProjectVersion).not_to receive(:publish!)
        subject
      end
    end

    context 'when using an illegal name' do
      subject { post :create, params: { name: 'Test', team_id: team.id } }

      it 'returns an error' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'creates a flash error' do
        subject
        expect(flash[:error]).to eq('Name must be lower case and contain only letters, numbers, hyphens and be less than 100 characters')
      end
    end
  end
end
