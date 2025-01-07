# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RepoClient do
  let(:repo_client) { RepoClient.new("my-repo", "my-user") }
  let(:project_version) { create(:project_version, project: create(:project, name: 'another-one')) }

  describe '#client_values_yaml_path' do
    it 'returns the correct path' do
      expect(repo_client.client_values_yaml_filename(project_version))
        .to eq("another-one-#{project_version.version}-values.yaml")
    end
  end
end
