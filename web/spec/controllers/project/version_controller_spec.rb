# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project::VersionController, type: :controller do
  let(:user) { create(:user, team:) }
  let(:team) { create(:team) }
  let!(:project) { create(:project, team:) }
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
    project_version.update!(version: '0.0.1')
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
        expect(flash[:error]).to eq('Application not found')
        expect(response).to redirect_to(root_path)
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
          version: '1.0.0',
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
        expect(response).to redirect_to(version_path(ProjectVersion.order(:created_at).last))
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

      context 'when the previous version has dependencies' do
        let!(:dependency) { create(:dependency, project_version:) }

        it 'creates a new version with the same dependencies' do
          expect { subject }.to change { Dependency.count }.by(1)
        end

        it 'creates a new version with the same dependency attributes' do
          expect { subject }.to change { Dependency.where(name: dependency.name).count }.by(1)
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
        expect(response).to redirect_to(version_path(project_version))
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

    context 'when there is an attached service and dependency' do
      let!(:project_service) { create(:project_service, project_version:) }
      let!(:dependency) { create(:dependency, project_version:) }

      let(:chart_publisher) { instance_double(Chart::Publisher) }

      before do
        allow(Chart::Publisher).to receive(:new).and_return(chart_publisher)
        allow(chart_publisher).to receive(:publish_chart!)
      end

      it 'publishes the version' do
        expect { subject }
          .to change { project_version.reload.published? }
                .from(false).to(true)
      end

      it 'calls the Chart::Publisher' do
        expect(Chart::Publisher).to receive(:new).with(project_version.rpc_chart, project_version)
        expect(chart_publisher).to receive(:publish_chart!)
        subject
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

  describe 'GET #client_values_yaml' do
    subject { get :client_values_yaml, params: { id: project_version.id } }

    let(:mock_file) { double('file') }
    let(:response_body) { 'client values yaml' }

    before do
      allow_any_instance_of(HelmRepo).to receive(:client_values_yaml).and_return(mock_file)
    end

    it_behaves_like 'requires authentication'

    context 'when the file is present' do
      before do
        allow(mock_file).to receive(:download).and_return(mock_file)
        allow(mock_file).to receive(:string).and_return(response_body)
      end

      it 'returns the client values yaml file' do
        subject
        expect(response.body).to eq(response_body)
      end
    end

    context 'when the file is not present' do
      let(:mock_file) { nil }

      it 'redirects to the project version page' do
        subject
        expect(flash[:error]).to eq('File not found')
        expect(response).to redirect_to(version_path(project_version))
      end
    end
  end
end
