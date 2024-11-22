# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project::ServiceController, type: :controller do
  let(:team) { create(:team) }
  let(:user) { create(:user, team:) }
  let(:project) { create(:project, team:) }
  let(:project_version) { create(:project_version, project:) }
  let!(:project_service) { create(:project_service, project_version:) }

  before { sign_in user }

  describe 'DELETE #destroy' do
    subject { delete :destroy, params: { id: project_service.id } }

    it 'deletes the service' do
      expect { subject }.to change { ProjectService.count }.by(-1)
    end

    it 'redirects to the project version path' do
      expect(subject).to redirect_to(version_path(project_version))
    end
  end

  describe 'GET #new' do
    subject { get :new, params: { version_id: project_version.id } }

    it 'renders the new template' do
      expect(subject).to render_template(:new)
    end
  end

  describe 'POST #create' do
    let(:valid_params) { {
      version_id: project_version.id,
      service_form: {
        service_id: project_service.id,
        name: 'service',
        image: 'image:1.2.1',
        cpu_cores: 1,
        memory_bytes: 2.gigabytes,
        pvc_mount_path: '/data',
        pvc_size_bytes: 10.gigabytes,
        environment_variables: [ { name: 'MY_ENV', value: 'value', templated: false } ],
        secrets: [ { name: 'MY_SECRET' } ],
        ports: [ { port: 80 }, { port: 443 } ]
      }
    } }

    subject { post :create, params: valid_params }

    context 'with valid params' do
      it 'creates a new service' do
        expect { subject }.to change { ProjectService.count }.by(1)
      end

      it 'redirects to the version path' do
        expect(subject).to redirect_to(version_path(project_version))
      end

      it 'sets a flash notice' do
        subject
        expect(flash[:notice]).to eq('Service service created')
      end

      it 'creates a service with the correct attributes' do
        subject
        service = ProjectService.order(:created_at).last
        expect(service.name).to eq('service')
        expect(service.image).to eq('image:1.2.1')
        expect(service.cpu_cores).to eq(1)
        expect(service.memory_bytes).to eq(2.gigabytes)
        expect(service.environment_variables.first['name']).to eq('MY_ENV')
        expect(service.environment_variables.first['value']).to eq('value')
        expect(service.secrets.first).to eq('MY_SECRET')
        expect(service.ports).to eq(%w[80 443])
      end

      it 'creates a service with the correct PVC attributes' do
        subject
        service = ProjectService.order(:created_at).last
        expect(service.pvc_mount_path).to eq('/data')
        expect(service.pvc_size_bytes).to eq(10.gigabytes)
      end
    end

    context 'with invalid image param' do
      let(:invalid_params) { valid_params.deep_merge(service_form: { image: 'image' }) }

      subject { post :create, params: invalid_params }

      it 'does not create a new service' do
        expect { subject }.not_to change { ProjectService.count }
      end

      it 'renders the new template' do
        expect(subject).to render_template(:new)
      end

      it 'sets a flash error' do
        subject
        expect(flash[:error]).to eq('Image must specify an image version and not latest')
      end
    end

    context 'with a secret name which is shared with an environment variable' do
      subject { post :create, params: invalid_params }

      let(:invalid_params) { valid_params.deep_merge(service_form: { secrets: [ { name: 'MY_ENV' } ] }) }

      it 'does not create a new service' do
        expect { subject }.not_to change { ProjectService.count }
      end

      it 'renders the new template' do
        expect(subject).to render_template(:new)
      end

      it 'sets a flash error' do
        subject
        expect(flash[:error]).to eq('Environment variables and secrets must have unique names. Duplicates found: MY_ENV')
      end
    end

    context 'with no environment variables or secrets' do
      let(:no_vars_valid_params) { valid_params.deep_merge(service_form: { environment_variables: [], secrets: [] }) }

      subject { post :create, params: no_vars_valid_params }

      it 'creates a new service' do
        expect { subject }.to change { ProjectService.count }.by(1)
      end

      it 'redirects to the version path' do
        expect(subject).to redirect_to(version_path(project_version))
      end

      it 'sets a flash notice' do
        subject
        expect(flash[:notice]).to eq('Service service created')
      end
    end

    context 'with empty environment variables and secrets' do
      let(:empty_vars_valid_params) { valid_params.deep_merge(service_form: { environment_variables: [ { name: '', value: '' } ], secrets: [ { name: '' } ] }) }

      subject { post :create, params: empty_vars_valid_params }

      it 'creates a new service' do
        expect { subject }.to change { ProjectService.count }.by(1)
      end

      it 'redirects to the version path' do
        expect(subject).to redirect_to(version_path(project_version))
      end

      it 'sets a flash notice' do
        subject
        expect(flash[:notice]).to eq('Service service created')
      end
    end

    context 'with empty ports' do
      let(:empty_ports_valid_params) { valid_params.deep_merge(service_form: { ports: [ { port: '' } ] }) }

      subject { post :create, params: empty_ports_valid_params }

      it 'creates a new service' do
        expect { subject }.to change { ProjectService.count }.by(1)
      end

      it 'sets no ports' do
        subject
        service = ProjectService.order(:created_at).last
        expect(service.ports).to eq([])
      end
    end

    context 'with no ports' do
      let(:no_ports_valid_params) { valid_params.deep_merge(service_form: { ports: [] }) }

      subject { post :create, params: no_ports_valid_params }

      it 'creates a new service' do
        expect { subject }.to change { ProjectService.count }.by(1)
      end

      it 'sets no ports' do
        subject
        service = ProjectService.order(:created_at).last
        expect(service.ports).to eq([])
      end
    end

    context 'with no PVC mount path or size' do
      subject { post :create, params: no_pvc_valid_params }

      let(:no_pvc_valid_params) { valid_params.deep_merge(service_form: { pvc_mount_path: nil, pvc_size_bytes: nil }) }

      it 'creates a new service' do
        expect { subject }.to change { ProjectService.count }.by(1)
      end
    end
  end

  describe 'GET #edit' do
    subject { get :edit, params: { id: project_service.id } }

    it 'renders the edit template' do
      expect(subject).to render_template(:edit)
    end
  end
end
