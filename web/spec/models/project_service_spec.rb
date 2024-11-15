# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProjectService do
  let(:project_version) { create(:project_version) }
  let(:service) do
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
    service.instance_variable_set(:@rpc_client, mock_client)
  end

  describe '#validate_chart' do
    context 'when chart is valid' do
      let(:response) { double('Response', valid: true, errors: []) }

      before do
        allow(mock_client).to receive(:send)
          .with(:validate_chart, kind_of(Sidecar::ValidateChartRequest))
          .and_return(response)
      end

      it 'returns true' do
        expect(service.validate_chart).to be true
      end

      it 'calls validate_chart with correct parameters' do
        expect(mock_client).to receive(:send) do |method, request|
          expect(method).to eq(:validate_chart)
          expect(request.chart.name).to eq('test-service')
          expect(request.chart.version).to eq(project_version.version)
          expect(request.chart.services.first.replica_count).to eq(1)
          expect(request.chart.services.first.endpoints).to contain_exactly(
            have_attributes(port: 80),
            have_attributes(port: 443)
          )
          response
        end

        service.validate_chart
      end
    end

    context 'when chart is invalid' do
      let(:validation_errors) { [ 'Invalid configuration', 'Resource limits too low' ] }
      let(:response) { double('Response', valid: false, errors: validation_errors) }

      before do
        allow(mock_client).to receive(:send)
                                .with(:validate_chart, kind_of(Sidecar::ValidateChartRequest))
                                .and_return(response)
        allow(Rails.logger).to receive(:info)
      end

      it 'returns false' do
        expect(service.validate_chart).to be false
      end

      it 'logs validation errors' do
        expected_error_message = "SideCar Validation Error: Invalid configuration\nSideCar Validation Error: Resource limits too low"
        expect(Rails.logger).to receive(:info).with(expected_error_message)
        service.validate_chart
      end
    end
  end

  describe '#publish_chart!' do
    let(:helm_repo) { create(:helm_repo, name: 'test-repo') }
    let(:response) { double('Response') }

    before do
      allow(service).to receive(:helm_repo).and_return(helm_repo)
      allow(mock_client).to receive(:send)
        .with(:publish_chart, kind_of(Sidecar::PublishChartRequest))
        .and_return(response)
    end

    it 'calls publish_chart with correct parameters' do
      expect(mock_client).to receive(:send) do |method, request|
        expect(method).to eq(:publish_chart)
        expect(request.chart.name).to eq('test-service')
        expect(request.chart.version).to eq(project_version.version)
        expect(request.chart.services.first.replica_count).to eq(1)
        expect(request.repository_directory).to eq('test-repo')
        expect(request.chart.services.first.endpoints).to contain_exactly(
          have_attributes(port: 80),
          have_attributes(port: 443)
        )
        response
      end

      service.publish_chart!
    end

    it 'includes correct helm repo name in request' do
      expect(mock_client).to receive(:send) do |_, request|
        expect(request.repository_directory).to eq(helm_repo.name)
        response
      end

      service.publish_chart!
    end
  end

  describe '#rpc_chart' do
    subject(:chart) { service.send(:rpc_chart) }

    it 'creates chart with correct attributes' do
      expect(chart.to_h.slice(:name, :version)).to eq(
                         name: 'test-service',
                         version: project_version.version,
                       )
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

  describe '#env_to_k8s_secret_name' do
    subject(:convert_name) { service.send(:env_to_k8s_secret_name, env_name) }

    {
      'NORMAL_ENV_VAR' => 'normal-env-var',
      'multiple--hyphens' => 'multiple-hyphens',
      '123numeric' => '123numeric',
      '_leading_underscore' => 'x-leading-underscore',
      'trailing_underscore_' => 'trailing-underscore-x',
      'a' * 260 => "#{('a' * 252)}",
      '!@#special#@!' => 'x-special-x'
    }.each do |input, expected|
      context "with input '#{input}'" do
        let(:env_name) { input }

        it "converts to '#{expected}'" do
          expect(convert_name).to eq(expected)
        end

        it 'produces valid Kubernetes secret name' do
          result = convert_name
          expect(result).to match(/^[a-z0-9][a-z0-9.-]*[a-z0-9]$/)
          expect(result.length).to be <= 253
        end
      end
    end
  end
end
