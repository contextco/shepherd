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
           secrets: [ 'TEST_SECRET' ],
           ports: %w[80 443]
    )
  end

  let(:mock_client) { double(:sidecar_client) }
  before do
    service.instance_variable_set(:@rpc_client, mock_client)
  end

  describe '#rpc_service' do
    it 'returns a Sidecar::ServiceParams object' do
      expect(service.rpc_service).to be_a(Sidecar::ServiceParams)
    end

    it 'sets the correct attributes' do
      expect(service.rpc_service.to_h).to eq(
        name: 'test-service',
        replica_count: 1,
        endpoints: [
          { port: 80 },
          { port: 443 }
        ],
        environment_config: {
          environment_variables: [
            { name: 'ENV_VAR1', value: 'value1' },
            { name: 'ENV_VAR2', value: 'value2' }
          ],
          secrets: [
            { name: 'test-secret', environment_key: 'TEST_SECRET' }
          ]
        },
        resources: {
          cpu_cores_requested: 2,
          cpu_cores_limit: 2,
          memory_bytes_requested: 512_000_000,
          memory_bytes_limit: 512_000_000
        },
        image: {
          name: 'registry.example.com/org/app',
          tag: 'v1.2.3'
        }
      )
    end

    context 'with predeploy command' do
      before do
        service.update!(predeploy_command: 'echo "predeploy"')
      end

      it 'sets the init_config attribute' do
        expect(service.rpc_service.init_config).to be_a(Sidecar::InitConfig)
        expect(service.rpc_service.init_config.init_commands).to eq([ 'echo "predeploy"' ])
      end
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
