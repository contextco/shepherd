# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Helm::RepoController, type: :controller do
  # this works locally without mocking but in test it does not
  let(:mock_bucket) { instance_double("Google::Cloud::Storage::Bucket") }
  let(:mock_file) { instance_double("Google::Cloud::Storage::File") }
  let(:file_content) { "apiVersion: v1\nentries: {}" }

  let(:username) { "test_user" }
  let(:password) { "test_password" }
  let(:helm_repo) { create(:helm_repo, name: 'sidecar') }
  let!(:helm_user) { create(:helm_user, name: username, password:, helm_repo:) }

  before do
    allow(GCSClient).to receive(:onprem_bucket).and_return(mock_bucket)
    allow(mock_bucket).to receive(:file).with("sidecar/index.yaml").and_return(mock_file)
    allow(mock_file).to receive_message_chain(:download, :string).and_return(file_content)

    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
  end

  describe 'GET #index_yaml' do
    it 'returns a success response' do
      get :index_yaml, params: { repo_name: "sidecar" }
      expect(response).to be_successful
    end

    it 'returns a yaml content type' do
      get :index_yaml, params: { repo_name: "sidecar" }
      expect(response.content_type).to eq('application/x-yaml; charset=utf-8')
    end

    it "returns a yaml file" do
      get :index_yaml, params: { repo_name: "sidecar" }
      expect(response.body).to include("apiVersion")
    end
  end
end
