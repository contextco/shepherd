# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Chart::Publisher do
  describe '#validate_chart!' do
    let(:project) { create(:project, name: "my-testing-project") }
    let(:project_version) { create(:project_version, project:) }
    let(:project_subscriber) { create(:project_subscriber, project_version:) }
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
             ports: %w[80 443],
      )
    end
    let(:client) { double('client') }
    let(:resp) { double('resp', errors: [], valid: true) }

    let(:publisher) { Chart::Publisher.new(project_subscriber) }

    subject(:validate) { publisher.validate_chart! }

    before do
      allow(SidecarClient).to receive(:client).and_return(client)
      allow(client).to receive(:send).and_return(resp)
    end

    it 'calls validate_chart with correct parameters' do
      expect(client).to receive(:send) do |method, request|
        expect(method).to eq(:validate_chart)
        expect(request.chart).to eq(publisher.send(:rpc_chart))
        resp
      end

      validate
    end

    context 'when chart is invalid' do
      let(:resp) { double('resp', errors: [ 'Invalid configuration' ], valid: false) }

      it 'raises ChartValidationError' do
        expect { validate }.to raise_error(Chart::Publisher::ChartValidationError)
      end

      it 'logs validation errors' do
        expect(Rails.logger).to receive(:info).with("SideCar Validation Error: Invalid configuration")
        expect { validate }.to raise_error(Chart::Publisher::ChartValidationError)
      end
    end
  end

  describe '#rpc_service' do
    let(:project) { create(:project, name: "my-testing-project") }
    let(:project_version) { create(:project_version, project:) }
    let(:project_subscriber) { create(:project_subscriber, project_version:) }
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
             pvc_name: 'test-pvc',
             pvc_mount_path: '/data',
             pvc_size_bytes: 10.gigabytes,
             secrets: [ 'TEST_SECRET' ],
             ports: %w[80 443],
             ingress_port: 443
      )
    end

    let(:rpc_service) { Chart::Publisher.new(project_subscriber).send(:rpc_service, service) }

    it 'returns a Sidecar::ServiceParams object' do
      expect(rpc_service).to be_a(Sidecar::ServiceParams)
    end

    it 'sets the correct attributes' do
      expect(rpc_service.to_h).to eq(
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
        expect(rpc_service.init_config).to be_a(Sidecar::InitConfig)
        expect(rpc_service.init_config.init_commands).to eq([ 'echo "predeploy"' ])
      end
    end

    context 'without ingress port' do
      before do
        service.update!(ingress_port: nil)
      end

      it 'does not set the ingress_config attribute' do
        expect(rpc_service.ingress_config).to be_nil
      end
    end

    context 'with image credentials' do
      before do
        service.update!(image_username: 'user', image_password: 'pass')
      end

      it 'sets the image credential attribute' do
        expect(rpc_service.image.credential).to be_a(Sidecar::ImageCredentials)
        expect(rpc_service.image.credential.username).to eq('user')
        expect(rpc_service.image.credential.password).to eq('pass')
      end
    end

    context 'without image credentials (default)' do
      it 'does not set the image credential attribute' do
        expect(rpc_service.image.credential).to be_nil
      end
    end
  end
end
