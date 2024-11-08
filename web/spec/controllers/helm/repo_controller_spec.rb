# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Helm::RepoController, type: :controller do
  describe 'GET #index_yaml' do
    it 'returns a success response' do
      get :index_yaml
      expect(response).to be_successful
    end

    it 'returns a yaml content type' do
      get :index_yaml
      expect(response.content_type).to eq('application/x-yaml; charset=utf-8')
    end

    it "returns a yaml file" do
      get :index_yaml
      expect(response.body).to include("apiVersion")
    end
  end
end
