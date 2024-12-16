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
           ports: [ 80, 443 ],
           pvc_name: 'test-pvc',
           pvc_size_bytes: 10.gigabytes,
           pvc_mount_path: '/data',
           ingress_port: 443
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
          tag: 'v1.2.3',
          pull_policy: :IMAGE_PULL_POLICY_IF_NOT_PRESENT
        },
        persistent_volume_claims: [
          {
            path: '/data',
            name: 'test-pvc',
            size_bytes: 10.gigabytes
          }
        ],
        ingress_config: {
          port: 443,
          preference: :PREFER_INTERNAL
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

    context 'without ingress port' do
      before do
        service.update!(ingress_port: nil)
      end

      it 'does not set the ingress_config attribute' do
        expect(service.rpc_service.ingress_config).to be_nil
      end
    end

    context 'with image credentials' do
      before do
        service.update!(image_username: 'user', image_password: 'pass')
      end

      it 'sets the image credential attribute' do
        expect(service.rpc_service.image.credential).to be_a(Sidecar::ImageCredentials)
        expect(service.rpc_service.image.credential.username).to eq('user')
        expect(service.rpc_service.image.credential.password).to eq('pass')
      end
    end

    context 'without image credentials (default)' do
      it 'does not set the image credential attribute' do
        expect(service.rpc_service.image.credential).to be_nil
      end
    end
  end

  describe '#secret.k8s_name' do
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
        let(:converted_name) { described_class::Secret.new(environment_key: env_name).k8s_name }

        it "converts to '#{expected}'" do
          expect(converted_name).to eq(expected)
        end

        it 'produces valid Kubernetes secret name' do
          result = converted_name
          expect(result).to match(/^[a-z0-9][a-z0-9.-]*[a-z0-9]$/)
          expect(result.length).to be <= 253
        end
      end
    end
  end
end
