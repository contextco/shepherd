# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Chart::Publisher do
  describe 'publish!' do
    around do |example|
      ENV['USE_LIVE_PUBLISHER'] = 'true'
      example.run
      ENV['USE_LIVE_PUBLISHER'] = nil
    end

    subject(:publish) { Chart::Publisher.publish!(project_version, project_subscriber) }

    let(:project_version) { create(:project_version) }
    let(:project_subscriber) { create(:project_subscriber, project_version:) }
    let(:client) { double('client') }
    let(:response) { double('Resposne') }
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
    let!(:dependency_redis) { create(:dependency, project_version:, name: 'redis') }
    let!(:dependency_postgresql) { create(:dependency, project_version:, name: 'postgresql', version: '17.x.x', repo_url: 'oci://registry-1.docker.io/bitnamicharts', chart_name: 'postgresql', configs: { cpu_cores: 32, disk_bytes: 5368709120, memory_bytes: 4294967296, db_name: 'test_db', db_user: 'test_user', db_password: 'test_pass' }) }

    before do
      allow(SidecarClient).to receive(:client).and_return(client)
      allow(client).to receive(:send).and_return(response)

      project_subscriber.setup_helm_repo!
    end

    context 'when agent is set to full' do
      let(:project_subscriber) { create(:project_subscriber, project_version:, agent: 'full') }

      it 'includes agent service' do
        expect(client).to receive(:send) do |_, request|
          expect(request.chart.services).to contain_exactly(
                                              have_attributes(name: 'test-service'),
                                              have_attributes(name: 'shepherd-agent')
                                            )
          response
        end

        publish
      end

      it 'includes correct agent service configuration' do
        expect(client).to receive(:send) do |_, request|
          expect(request.chart.services.last).to have_attributes(
                                                   image: Sidecar::Image.new(
                                                     name: "ghcr.io/contextco/shepherd",
                                                     tag: "master",
                                                     pull_policy: 'IMAGE_PULL_POLICY_ALWAYS'
                                                   ),
                                                   resources: Sidecar::Resources.new(
                                                     cpu_cores_requested: 1,
                                                     cpu_cores_limit: 1,
                                                     memory_bytes_requested: 2.gigabytes,
                                                     memory_bytes_limit: 2.gigabytes
                                                   ),
                                                   environment_config: Sidecar::EnvironmentConfig.new(
                                                     meta_environment_fields_enabled: true,
                                                     environment_variables: [
                                                       Sidecar::EnvironmentVariable.new(name: 'NAME', value: project_subscriber.name),
                                                       Sidecar::EnvironmentVariable.new(name: 'BEARER_TOKEN', value: project_subscriber.tokens.first.token),
                                                       Sidecar::EnvironmentVariable.new(name: 'BACKEND_ADDR', value: ENV['SHEPHERD_AGENT_API_ENDPOINT'] || 'https://agent.trustshepherd.com'),
                                                       Sidecar::EnvironmentVariable.new(name: 'SHEPHERD_PROJECT_VERSION_ID', value: project_version.id.to_s)
                                                     ]
                                                   )
                                                 )
        end

        publish
      end
    end

    it 'calls publish_chart twice with correct parameters' do
      expect(client).to receive(:send) do |method, request|
        expect(method).to eq(:publish_chart)
        expect(request.chart.name).to eq(project_version.project.name)
        expect(request.chart.version).to eq(project_version.version)
        expect(request.chart.services.first.replica_count).to eq(1)
        expect(request.repository_directory).to eq(project_subscriber.helm_repo.repo_name)
        expect(request.chart.services.first.endpoints).to contain_exactly(
                                                            have_attributes(port: 80),
                                                            have_attributes(port: 443)
                                                          )
        expect(request.chart.dependencies.first.name).to eq("redis")
        expect(request.chart.dependencies.first.version).to eq(dependency_redis.version)
        expect(request.chart.dependencies.first.repository_url).to eq(dependency_redis.repo_url)
        expect(request.chart.dependencies.first.overrides).to contain_exactly(
                                                                Sidecar::OverrideParams.new(path: 'master.resources.requests.cpu', value: Google::Protobuf::Value.new(number_value: 4.0)),
                                                                Sidecar::OverrideParams.new(path: 'master.resources.limits.cpu', value: Google::Protobuf::Value.new(number_value: 4.0)),
                                                                Sidecar::OverrideParams.new(path: 'master.resources.requests.memory', value: Google::Protobuf::Value.new(number_value: 4294967296.0)),
                                                                Sidecar::OverrideParams.new(path: 'master.resources.limits.memory', value: Google::Protobuf::Value.new(number_value: 4294967296.0)),
                                                                Sidecar::OverrideParams.new(path: 'master.persistence.size', value: Google::Protobuf::Value.new(string_value: '5Gi')),
                                                                Sidecar::OverrideParams.new(path: 'auth.password', value: Google::Protobuf::Value.new(string_value: 'password')),
                                                                Sidecar::OverrideParams.new(path: 'master.extraFlags', value: Google::Protobuf::Value.new(list_value: Google::Protobuf::ListValue.new(values: [ Google::Protobuf::Value.new(string_value: '--maxmemory-policy volatile-lru') ])))
                                                              )

        expect(request.chart.dependencies[1].name).to eq("postgresql")
        expect(request.chart.dependencies[1].version).to eq(dependency_postgresql.version)
        expect(request.chart.dependencies[1].repository_url).to eq(dependency_postgresql.repo_url)
        expect(request.chart.dependencies[1].overrides).to contain_exactly(
                                                             Sidecar::OverrideParams.new(path: 'primary.resources.requests.cpu', value: Google::Protobuf::Value.new(number_value: 32.0)),
                                                             Sidecar::OverrideParams.new(path: 'primary.resources.limits.cpu', value: Google::Protobuf::Value.new(number_value: 32.0)),
                                                             Sidecar::OverrideParams.new(path: 'primary.resources.requests.memory', value: Google::Protobuf::Value.new(number_value: 4294967296.0)),
                                                             Sidecar::OverrideParams.new(path: 'primary.resources.limits.memory', value: Google::Protobuf::Value.new(number_value: 4294967296.0)),
                                                             Sidecar::OverrideParams.new(path: 'primary.persistence.size', value: Google::Protobuf::Value.new(string_value: '5Gi')),
                                                             Sidecar::OverrideParams.new(path: 'auth.database', value: Google::Protobuf::Value.new(string_value: 'test_db')),
                                                             Sidecar::OverrideParams.new(path: 'auth.username', value: Google::Protobuf::Value.new(string_value: 'test_user')),
                                                             Sidecar::OverrideParams.new(path: 'auth.password', value: Google::Protobuf::Value.new(string_value: 'test_pass'))
                                                           )

        response
      end

      publish
    end

    it 'includes correct helm repo name in request' do
      expect(client).to receive(:send) do |_, request|
        expect(request.repository_directory).to eq(project_subscriber.helm_repo.repo_name)
        response
      end

      publish
    end

    it 'only creates one service (no agent)' do
      expect(client).to receive(:send) do |_, request|
        expect(request.chart.services.length).to eq(1)
        response
      end

      publish
    end

    context 'when calling with a specific project subscriber' do
      context 'when the project subscriber is a dummy' do
        it 'includes correct helm repo name in request' do
          expect(client).to receive(:send) do |_, request|
            expect(request.repository_directory).to eq(project_subscriber.helm_repo.client.internal_repo_name)
            response
          end

          publish
        end

        it 'does not update the state to published' do
          expect(project_version).not_to receive(:published!)

          publish
        end
      end

      context 'when the project subscriber is not a dummy' do
        let!(:project_subscriber) { create(:project_subscriber, project_version:) }

        it 'includes correct helm repo name in request' do
          expect(client).to receive(:send) do |_, request|
            expect(request.repository_directory).to eq(project_subscriber.helm_repo.repo_name)
            response
          end

          publish
        end
      end
    end

    context 'when agent is set to full' do
      let(:project_subscriber) { create(:project_subscriber, project_version:, agent: 'full') }

      it 'includes agent service' do
        expect(client).to receive(:send) do |_, request|
          expect(request.chart.services).to contain_exactly(
                                              have_attributes(name: 'test-service'),
                                              have_attributes(name: 'shepherd-agent')
                                            )
          response
        end

        publish
      end

      it 'includes correct agent service configuration' do
        expect(client).to receive(:send) do |_, request|
          expect(request.chart.services.last).to have_attributes(
                                                   image: Sidecar::Image.new(
                                                     name: "ghcr.io/contextco/shepherd",
                                                     tag: "master",
                                                     pull_policy: 'IMAGE_PULL_POLICY_ALWAYS'
                                                   ),
                                                   resources: Sidecar::Resources.new(
                                                     cpu_cores_requested: 1,
                                                     cpu_cores_limit: 1,
                                                     memory_bytes_requested: 2.gigabytes,
                                                     memory_bytes_limit: 2.gigabytes
                                                   ),
                                                   environment_config: Sidecar::EnvironmentConfig.new(
                                                     meta_environment_fields_enabled: true,
                                                     environment_variables: [
                                                       Sidecar::EnvironmentVariable.new(name: 'NAME', value: project_subscriber.name),
                                                       Sidecar::EnvironmentVariable.new(name: 'BEARER_TOKEN', value: project_subscriber.tokens.first.token),
                                                       Sidecar::EnvironmentVariable.new(name: 'BACKEND_ADDR', value: ENV['SHEPHERD_AGENT_API_ENDPOINT'] || 'https://agent.trustshepherd.com'),
                                                       Sidecar::EnvironmentVariable.new(name: 'SHEPHERD_PROJECT_VERSION_ID', value: project_version.id.to_s)
                                                     ]
                                                   )
                                                 )
        end

        publish
      end
    end
  end

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

    let(:publisher) { Chart::Publisher.new(project_version, subscriber: project_subscriber) }

    subject(:validate) { publisher.validate_chart! }

    before do
      allow(SidecarClient).to receive(:client).and_return(client)
      allow(client).to receive(:send).and_return(resp)
    end

    it 'calls validate_chart with correct parameters' do
      expect(client).to receive(:send) do |method, request|
        expect(method).to eq(:validate_chart)
        expect(request.chart).to eq(publisher.chart_proto)
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

    let(:rpc_service) { Chart::Publisher.new(project_version, subscriber: project_subscriber).send(:rpc_service, service) }

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
