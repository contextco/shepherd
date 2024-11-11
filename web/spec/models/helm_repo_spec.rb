# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HelmRepo do
  let(:project) { helm_repo.project }
  let(:project_version) { create(:project_version, project:) }
  let(:helm_repo) { create(:helm_repo, name: 'test-repo') }
  let!(:helm_user) { create(:helm_user, helm_repo:, name: 'test-user', password: 'test-password') }
  let!(:project_service) { create(:project_service, name: 'test-service', project_version:) }

  describe '#add_repo_command' do
    it 'returns the correct command' do
      expect(helm_repo.add_repo_command).to eq("helm repo add test-repo https://vpc.context.ai/test-repo --username test-user --password test-password --insecure-skip-tls-verify")
    end
  end

  describe '#pull_chart_command' do
    it 'returns the correct command' do
      expect(helm_repo.pull_chart_command(service_name: 'test-service')).to eq("helm pull test-repo/test-service --untar")
    end
  end

  describe '#install_chart_command' do
    it 'returns the correct command' do
      expect(helm_repo.install_chart_command(service_name: 'test-service')).to eq("helm install test-service test-repo/test-service")
    end
  end
end
