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
      subject { post :create, params: { name: 'test', team_id: team.id } }

      it 'creates a new project' do
        subject
        expect(response).to redirect_to(version_path(Project.last.latest_version))
      end

      it 'creates a new project version' do
        subject
        expect(Project.last.project_versions.count).to eq(1)
      end

      it 'creates a new helm repo' do
        subject
        expect(Project.last.helm_repo).to be_present
      end

      it 'creates a new helm user' do
        subject
        expect(Project.last.helm_repo.helm_users.count).to eq(1)
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
