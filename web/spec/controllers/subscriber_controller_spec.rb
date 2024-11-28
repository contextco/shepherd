# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriberController, type: :request do
  let(:team) { create(:team) }
  let(:user) { create(:user, team:) }
  let(:subscriber) { create(:project_subscriber, project:) }
  let!(:project) { create(:project, team:) }
  let(:project_version) { create(:project_version, project:) }

  before do
    login_as user
  end

  describe 'GET #show' do
    subject { get project_subscriber_path(subscriber) }

    it 'returns a success response' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #create' do
    subject { post project_subscriber_index_path, params: { project_subscriber: { name: 'test', project_id: project.id, auth: true } } }

    it 'creates a new subscriber' do
      expect { subject }.to change { ProjectSubscriber.count }.by(1)
    end

    it 'redirects to the subscriber index path' do
      subject
      expect(response).to redirect_to(project_subscriber_index_path)
    end

    it 'creates a new helm repo' do
      expect { subject }.to change { HelmRepo.count }.by(1)
    end

    it 'creates a new helm user' do
      expect { subject }.to change { HelmUser.count }.by(1)
    end

    it 'creates a subscriber with the correct attributes' do
      subject
      subscriber = ProjectSubscriber.order(:created_at).last
      expect(subscriber.name).to eq('test')
      expect(subscriber.project_id).to eq(project.id)
      expect(subscriber.auth).to eq(true)
    end

    context 'when auth is false' do
      subject { post project_subscriber_index_path, params: { project_subscriber: { name: 'test', project_id: project.id, auth: false } } }

      it 'creates a new subscriber' do
        expect { subject }.to change { ProjectSubscriber.count }.by(1)
      end

      it 'sets auth to false' do
        subject
        subscriber = ProjectSubscriber.order(:created_at).last
        expect(subscriber.auth).to eq(false)
      end
    end
  end

  describe 'DELETE #destroy' do
    subject { delete project_subscriber_path(subscriber) }

    it 'deletes the subscriber' do
      subscriber
      expect { subject }.to change { ProjectSubscriber.count }.by(-1)
    end

    it 'redirects to the subscriber index path' do
      subject
      expect(response).to redirect_to(project_subscriber_index_path)
    end
  end

  describe 'GET #new' do
    subject { get new_project_subscriber_path }

    it 'returns a success response' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #client_values_yaml' do
    subject { get client_values_yaml_project_subscriber_path(project_version_id: project_version.id, id: subscriber.id) }

    let(:mock_file) { double('file') }
    let(:response_body) { 'client values yaml' }

    before do
      allow_any_instance_of(HelmRepo).to receive(:client_values_yaml).and_return(mock_file)
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
        expect(response).to redirect_to(project_subscriber_path(subscriber))
      end
    end
  end
end
