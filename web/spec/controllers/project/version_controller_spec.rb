# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project::VersionController, type: :controller do
  let(:user) { create(:user, team:) }
  let(:team) { create(:team) }
  let(:project) { create(:project, team:) }
  let(:project_version) { project.project_versions.first }
  let(:valid_params) do
    {
      project_id: project.id,
      id: project_version.id,
      description: 'New description'
    }
  end

  before do
    sign_in user
  end

  shared_examples 'requires authentication' do
    context 'when user is not signed in' do
      before { sign_out user }

      it 'redirects to login page' do
        subject
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET #show' do
    subject { get :show, params: { project_id: project.id, id: project_version.id } }

    it_behaves_like 'requires authentication'

    context 'when user has access' do
      it 'returns http success' do
        subject
        expect(response).to have_http_status(:success)
      end

      it 'assigns the requested version' do
        subject
        expect(assigns(:version)).to eq(project_version)
      end
    end

    context 'when user does not have access' do
      let(:other_team) { create(:team) }
      let(:user) { create(:user, team: other_team) }

      it 'returns forbidden status' do
        subject
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET #new' do
    subject { get :new, params: { project_id: project.id } }

    it_behaves_like 'requires authentication'

    context 'when user has access' do
      it 'returns http success' do
        subject
        expect(response).to have_http_status(:success)
      end

      it 'assigns previous version' do
        subject
        expect(assigns(:previous_version)).to eq(project_version)
      end
    end
  end

  describe 'POST #create' do
    subject { post :create, params: valid_params }

    let(:valid_params) do
      {
        project_version: {
          major_version: 1,
          minor_version: 0,
          patch_version: 1,
          description: 'New version'
        },
        project_id: project.id
      }
    end

    it_behaves_like 'requires authentication'

    context 'with valid params' do
      it 'creates a new version' do
        expect { subject }.to change { ProjectVersion.count }.by(1)
      end

      it 'redirects to the project version page' do
        subject
        expect(response).to redirect_to(project_version_path(project, ProjectVersion.order(:created_at).last))
      end

      it 'sets a success flash message' do
        subject
        expect(flash[:notice]).to eq('Application version created')
      end

      context 'when the previous version has services' do
        let!(:service) { create(:project_service, project_version:) }

        it 'creates a new version with the same services' do
          expect { subject }.to change { ProjectService.count }.by(1)
        end

        it 'creates a new version with the same service attributes' do
          expect { subject }.to change { ProjectService.where(name: service.name).count }.by(1)
        end
      end
    end
  end

  describe 'GET #edit' do
    subject { get :edit, params: { project_id: project.id, id: project_version.id } }

    it_behaves_like 'requires authentication'

    context 'when user has access' do
      it 'returns http success' do
        subject
        expect(response).to have_http_status(:success)
      end

      it 'assigns the requested version' do
        subject
        expect(assigns(:version)).to eq(project_version)
      end
    end
  end

  describe 'PATCH #update' do
    subject { patch :update, params: valid_params }

    it_behaves_like 'requires authentication'

    context 'with valid params' do
      it 'updates the description' do
        expect { subject }
          .to change { project_version.reload.description }
                .to('New description')
      end

      it 'redirects to the project version page' do
        subject
        expect(response).to redirect_to(project_version_path(project, project_version))
      end

      it 'sets a success flash message' do
        subject
        expect(flash[:notice]).to eq('Application version updated')
      end
    end
  end

  describe 'POST #publish' do
    subject { post :publish, params: { project_id: project.id, id: project_version.id } }

    it_behaves_like 'requires authentication'

    context 'when there is an attached service' do
      let!(:project_service) { create(:project_service, project_version:) }

      before do
        allow_any_instance_of(ProjectService).to receive(:publish_chart).and_return(true)
      end

      it 'publishes the version' do
        expect { subject }
          .to change { project_version.reload.published? }
                .from(false).to(true)
      end

      it 'sets a success flash message' do
        subject
        expect(flash[:notice]).to eq('Application version published')
      end
    end
  end

  describe 'POST #unpublish' do
    subject { post :unpublish, params: { project_id: project.id, id: project_version.id } }

    it_behaves_like 'requires authentication'

    context 'when user has access' do
      it 'unpublishes the version' do
        project_version.published!
        expect { subject }
          .to change { project_version.reload.draft? }
                .from(false).to(true)
      end

      it 'sets a success flash message' do
        subject
        expect(flash[:notice]).to eq('Application version unpublished')
      end
    end
  end
end
