# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriberController, type: :request do
  let(:team) { create(:team) }
  let(:user) { create(:user, team:) }
  let(:subscriber) { create(:project_subscriber, project_version:) }
  let!(:project) { create(:project, team:) }
  let(:project_version) { create(:project_version, project:) }

  before do
    login_as user
  end

  describe 'GET #show' do
    subject { get subscriber_path(subscriber) }

    it 'returns a success response' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #create' do
    subject { post project_subscribers_path(project), params: { project_subscriber: { name: 'test', project_version_id: project_version.id, auth: true, agent: 'full' } } }

    it 'creates a new subscriber' do
      expect { subject }.to change { project_version.subscribers.count }.by(1)
    end

    it 'redirects to the subscriber index path' do
      subject
      expect(response).to redirect_to(subscribers_path)
    end

    it 'creates a subscriber with the correct attributes' do
      subject
      subscriber = project_version.subscribers.order(:created_at).last
      expect(subscriber.name).to eq('test')
      expect(subscriber.auth).to eq(true)
      expect(subscriber.full_agent?).to be true
    end

    it 'creates a helm repo' do
      subject
      subscriber = project_version.subscribers.order(:created_at).last
      expect(subscriber.helm_repo).to be_present
    end

    context 'when agent is false' do
      subject { post project_subscribers_path(project), params: { project_subscriber: { name: 'test', project_version_id: project_version.id, auth: true, agent: 'no' } } }

      it 'does not add an agent' do
        subject
        subscriber = project_version.subscribers.order(:created_at).last
        expect(subscriber.full_agent?).to be false
      end
    end

    context 'when auth is false' do
      subject { post project_subscribers_path(project), params: { project_subscriber: { name: 'test', project_version_id: project_version.id, auth: false } } }

      it 'creates a new subscriber' do
        expect { subject }.to change { ProjectSubscriber.non_dummy.count }.by(1)
      end

      it 'sets auth to false' do
        subject
        subscriber = ProjectSubscriber.non_dummy.order(:created_at).last
        expect(subscriber.auth).to eq(false)
      end
    end
  end

  describe 'DELETE #destroy' do
    subject { delete subscriber_path(subscriber) }

    it 'deletes the subscriber' do
      subscriber
      expect { subject }.to change { project_version.subscribers.count }.by(-1)
    end

    it 'redirects to the subscriber index path' do
      subject
      expect(response).to redirect_to(subscribers_path)
    end
  end

  describe 'GET #new' do
    subject { get new_project_subscriber_path(project, version_id: project_version.id) }

    it 'returns a success response' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #client_values_yaml' do
    subject { get client_values_yaml_subscriber_path(project_version_id: project_version.id, id: subscriber.id) }

    let(:mock_file) { double('file') }
    let(:response_body) { 'client values yaml' }

    before do
      allow_any_instance_of(RepoClient).to receive(:client_values_yaml_file).and_return(mock_file)
      allow(mock_file).to receive(:name).and_return('values-1.0.0.yaml')

      subscriber.setup_helm_repo!
    end

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

      it 'redirects to the subscriber path with an error message' do
        subject
        expect(flash[:error]).to eq('File not found')
        expect(response).to redirect_to(subscriber_path(subscriber))
      end
    end
  end

  describe 'GET #deploy' do
    subject { get deploy_subscriber_path(subscriber, project_version_id: project_version.id) }

    it 'returns a success response' do
      subject
      expect(response).to have_http_status(:ok)
    end

    it 'assigns the subscriber' do
      subject
      expect(assigns(:version_comparison).base_version).to eq(subscriber.project_version)
    end

    it 'assigns the candidate version' do
      subject
      expect(assigns(:version_comparison).incoming_version).to eq(project_version)
    end
  end
end
