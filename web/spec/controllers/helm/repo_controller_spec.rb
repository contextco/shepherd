# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Helm::RepoController, type: :controller do
  let(:mock_bucket) { instance_double("Google::Cloud::Storage::Bucket") }
  let(:mock_file) { instance_double("Google::Cloud::Storage::File") }
  let(:file_content) { "apiVersion: v1\nentries: {}" }
  let(:signed_url) { "https://storage.googleapis.com/test-signed-url" }

  let(:username) { "test_user" }
  let(:password) { "test_password" }
  let(:helm_repo) { create(:helm_repo, name: 'sidecar') }
  let!(:helm_user) { create(:helm_user, name: username, password:, helm_repo:) }

  before do
    allow(GCSClient).to receive(:onprem_bucket).and_return(mock_bucket)
    allow(mock_bucket).to receive(:file).with("sidecar-test_user/index.yaml").and_return(mock_file)
    allow(mock_bucket).to receive(:file).with("sidecar-test_user/test-0.0.1.tgz").and_return(mock_file)
    allow(mock_file).to receive_message_chain(:download, :string).and_return(file_content)

    allow(mock_file).to receive(:signed_url).with(
      version: :v4,
      expires: 300,
      query: {
        'response-content-disposition' => "attachment; filename=test-0.0.1.tgz",
        'response-content-type' => 'application/x-tar'
      }
    ).and_return(signed_url)

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

  describe 'GET #download' do
    it 'redirects to signed URL' do
      get :download, params: { repo_name: "sidecar", filename: "test-0.0.1.tgz" }
      expect(response).to redirect_to(signed_url)
      expect(response.status).to eq(307) # temporary_redirect status
    end

    it 'returns not found for invalid file' do
      allow(mock_bucket).to receive(:file).with("sidecar-test_user/nonexistent.tgz").and_return(nil)
      get :download, params: { repo_name: "sidecar", filename: "nonexistent.tgz" }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns bad request for invalid filename' do
      get :download, params: { repo_name: "sidecar", filename: "../test-0.0.1.tgz" }
      expect(response).to have_http_status(:bad_request)
    end

    it 'handles signed URL generation errors' do
      allow(mock_file).to receive(:signed_url).and_raise(StandardError.new("Failed to generate URL"))
      get :download, params: { repo_name: "sidecar", filename: "test-0.0.1.tgz" }
      expect(response).to have_http_status(:internal_server_error)
      expect(JSON.parse(response.body)["error"]).to eq("Could not generate download URL")
    end
  end
end
