# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HelmRepo do
  let(:project) { create(:project, name: 'another-one') }
  let(:project_version) { create(:project_version, project:) }
  let(:project_subscriber) { create(:project_subscriber, project_version:) }
  let(:helm_repo) { create(:helm_repo, name: 'test-repo', project_subscriber:) }
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

  describe '#valid_credentials?' do
    context 'when the repo is private (default)' do
      it 'returns true if the credentials are correct' do
        expect(helm_repo.valid_credentials?('test-user', 'test-password')).to be true
      end

      it 'returns false if the credentials are incorrect' do
        expect(helm_repo.valid_credentials?('test-user', 'wrong-password')).to be false
      end
    end
  end
end
