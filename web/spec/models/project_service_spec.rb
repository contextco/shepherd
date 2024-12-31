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
