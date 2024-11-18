# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProjectVersion do
  let(:project) { create(:project, name: "my-testing-project") }
  let(:project_version) { create(:project_version, project:) }
  let!(:service) do
    create(:project_service,
           project_version:,
           name: 'test-service',
           image: 'registry.example.com/org/app:v1.2.3',
           cpu_cores: 2,
           memory_bytes: 512_000_000,
           environment_variables: [
             { 'name' => 'ENV_VAR1', 'value' => 'value1' },
             { 'name' => 'ENV_VAR2', 'value' => 'value2' }
           ],
           ports: %w[80 443]
    )
  end

  let(:mock_client) { double(:sidecar_client) }

  before do
    allow(SidecarClient).to receive(:client).and_return(mock_client)
  end

  describe '#publish!' do
    let(:helm_repo) { create(:helm_repo, name: 'test-repo') }
    let(:response) { double('Response') }

    before do
      allow(project_version).to receive(:helm_repo).and_return(helm_repo)
      allow(mock_client).to receive(:send)
        .with(:publish_chart, kind_of(Sidecar::PublishChartRequest))
        .and_return(response)
    end

    it 'calls publish_chart with correct parameters' do
      expect(mock_client).to receive(:send) do |method, request|
        expect(method).to eq(:publish_chart)
        expect(request.chart.name).to eq('my-testing-project')
        expect(request.chart.version).to eq(project_version.version)
        expect(request.chart.services.first.replica_count).to eq(1)
        expect(request.repository_directory).to eq('test-repo')
        expect(request.chart.services.first.endpoints).to contain_exactly(
          have_attributes(port: 80),
          have_attributes(port: 443)
        )
        response
      end

      project_version.publish!
    end

    it 'includes correct helm repo name in request' do
      expect(mock_client).to receive(:send) do |_, request|
        expect(request.repository_directory).to eq(helm_repo.name)
        response
      end

      project_version.publish!
    end
  end

  describe '#rpc_chart' do
    subject(:chart) { project_version.send(:rpc_chart) }

    it 'creates chart with correct attributes' do
      expect(chart.to_h.slice(:name, :version))
        .to eq(name: 'my-testing-project', version: project_version.version)
    end

    it 'includes correct image configuration' do
      expect(chart.services.first.image).to have_attributes(
                                              name: 'registry.example.com/org/app',
                                              tag: 'v1.2.3'
                                            )
    end

    it 'includes correct resource configuration' do
      expect(chart.services.first.resources).to have_attributes(
                                                  cpu_cores_requested: 2,
                                                  cpu_cores_limit: 2,
                                                  memory_bytes_requested: 512_000_000,
                                                  memory_bytes_limit: 512_000_000
                                                )
    end

    it 'includes correct environment variables' do
      env_vars = chart.services.first.environment_config.environment_variables
      expect(env_vars).to contain_exactly(
                            have_attributes(name: 'ENV_VAR1', value: 'value1'),
                            have_attributes(name: 'ENV_VAR2', value: 'value2')
                          )
    end

    it 'includes correct services' do
      services = chart.services.first.endpoints
      expect(services).to contain_exactly(
                            have_attributes(port: 80),
                            have_attributes(port: 443)
                          )
    end
  end

  describe '#client_values_yaml_path' do
    it 'returns the correct path' do
      expect(project_version.client_values_yaml_path).to eq("my-testing-project/my-testing-project-#{project_version.version}-values.yaml")
    end
  end
end
