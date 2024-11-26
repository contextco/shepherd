# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HelmRepo do
  let(:project) { create(:project, name: 'another-one') }
  let(:project_version) { create(:project_version, project:) }
  let(:helm_repo) { create(:helm_repo, name: 'test-repo', project:) }
  let!(:helm_user) { create(:helm_user, helm_repo:, name: 'test-user', password: 'test-password') }
  let!(:service) { create(:project_service, name: 'test-service', project_version:) }

  describe '#add_repo_command' do
    it 'returns the correct command' do
      expect(helm_repo.add_repo_command).to eq("helm repo add test-repo http://localhost:3000/repo/test-repo --username test-user --password test-password --insecure-skip-tls-verify")
    end
  end

  describe '#pull_chart_command' do
    it 'returns the correct command' do
      expect(helm_repo.pull_chart_command).to eq("helm pull test-repo/another-one --untar")
    end
  end

  describe '#install_chart_command' do
    it 'returns the correct command' do
      expect(helm_repo.install_chart_command(version: project_version)).to eq("helm install -f values-#{project_version.version}.yaml --create-namespace --namespace another-one another-one test-repo/another-one --version #{project_version.version}")
    end
  end

  describe '#client_values_yaml_path' do
    it 'returns the correct path' do
      expect(helm_repo.send(:client_values_yaml_path, version: project_version)).to eq("test-repo-test-user/another-one-#{project_version.version}-values.yaml")
    end
  end
end
