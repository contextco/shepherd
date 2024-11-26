# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriberController, type: :request do
  let(:team) { create(:team) }
  let(:user) { create(:user, team:) }
  let(:subscriber) { create(:project_subscriber, project:) }
  let(:project) { create(:project, team:) }
  let(:project_version) { create(:project_version, project:) }

  before do
    login_as user
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
