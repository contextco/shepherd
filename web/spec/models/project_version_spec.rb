# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProjectVersion do
  let!(:project) { create(:project, name: "my-testing-project") }
  let(:project_version) { create(:project_version, project:) }
  let(:project_subscriber) { project.dummy_project_subscriber }
  let(:helm_repo) { project.dummy_project_subscriber.helm_repo }
  let(:helm_user) { project.dummy_project_subscriber.helm_repo.helm_user }
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

  let(:mock_client) { double(:sidecar_client) }

  before do
    allow(SidecarClient).to receive(:client).and_return(mock_client)
  end

  describe '#publish!' do
    let(:response) { double('Response') }

    before do
      allow(mock_client).to receive(:send)
        .with(:publish_chart, kind_of(Sidecar::PublishChartRequest))
        .and_return(response)
    end

    it 'calls publish_chart twice with correct parameters' do
      expect(mock_client).to receive(:send) do |method, request|
        expect(method).to eq(:publish_chart)
        expect(request.chart.name).to eq('my-testing-project')
        expect(request.chart.version).to eq(project_version.version)
        expect(request.chart.services.first.replica_count).to eq(1)
        expect(request.repository_directory).to eq(helm_repo.repo_name)
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

      project_version.publish!
    end

    it 'includes correct helm repo name in request' do
      expect(mock_client).to receive(:send) do |_, request|
        expect(request.repository_directory).to eq(helm_repo.repo_name)
        response
      end

      project_version.publish!
    end

    it 'only creates one service (no agent)' do
      expect(mock_client).to receive(:send) do |_, request|
        expect(request.chart.services.length).to eq(1)
        response
      end

      project_version.publish!
    end

    context 'when calling with a specific project subscriber' do
      context 'when the project subscriber is a dummy' do
        it 'includes correct helm repo name in request' do
          expect(mock_client).to receive(:send) do |_, request|
            expect(request.repository_directory).to eq(helm_repo.repo_name)
            response
          end

          project_version.publish!(project_subscriber: project.dummy_project_subscriber)
        end

        it 'does not update the state to published' do
          expect(project_version).not_to receive(:published!)

          project_version.publish!(project_subscriber: project.dummy_project_subscriber)
        end
      end

      context 'when the project subscriber is not a dummy' do
        let!(:project_subscriber) { create(:project_subscriber, project:) }

        it 'includes correct helm repo name in request' do
          expect(mock_client).to receive(:send) do |_, request|
            expect(request.repository_directory).to eq(project_subscriber.helm_repo.repo_name)
            response
          end

          project_version.publish!(project_subscriber: project_subscriber)
        end

        it 'updates the state to published' do
          expect(project_version).to receive(:published!)

          project_version.publish!(project_subscriber:)
        end
      end
    end

    context 'when agent is set to full' do
      let(:project_version) { create(:project_version, project:, agent: 'full') }

      it 'includes agent service' do
        expect(mock_client).to receive(:send) do |_, request|
          expect(request.chart.services).to contain_exactly(
            have_attributes(name: 'test-service'),
            have_attributes(name: 'shepherd-agent')
          )
          response
        end

        project_version.publish!
      end

      it 'includes correct agent service configuration' do
        expect(mock_client).to receive(:send) do |_, request|
          expect(request.chart.services.last).to have_attributes(
              image: Sidecar::Image.new(
                name: "ghcr.io/contextco/onprem",
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
                environment_variables: [
                  Sidecar::EnvironmentVariable.new(name: 'NAME', value: project.dummy_project_subscriber.name),
                  Sidecar::EnvironmentVariable.new(name: 'BEARER_TOKEN', value: project.dummy_project_subscriber.tokens.first.token),
                  Sidecar::EnvironmentVariable.new(name: 'BACKEND_ADDR', value: 'https://agent.trustshepherd.com')
                ]
              )
          )
        end

        project_version.publish!
      end
    end
  end

  describe '#rpc_chart' do
    subject(:chart) { Chart::Publisher.new(project_version, project_subscriber, []).send(:rpc_chart) }

    it 'creates chart with correct attributes' do
      expect(chart.to_h.slice(:name, :version))
        .to eq(name: 'my-testing-project', version: project_version.version)
    end

    it 'includes correct image configuration' do
      expect(chart.services.first.image).to have_attributes(
                                              name: 'registry.example.com/org/app',
                                              tag: 'v1.2.3',
                                              pull_policy: :IMAGE_PULL_POLICY_IF_NOT_PRESENT
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

    it 'includes correct redis dependency' do
      expect(chart.dependencies.first).to have_attributes(
        name: "redis",
        version: dependency_redis.version,
        repository_url: dependency_redis.repo_url
      )

      overrides = chart.dependencies.first.overrides
      expect(overrides).to contain_exactly(
        Sidecar::OverrideParams.new(path: 'master.resources.requests.cpu', value: Google::Protobuf::Value.new(number_value: 4.0)),
        Sidecar::OverrideParams.new(path: 'master.resources.limits.cpu', value: Google::Protobuf::Value.new(number_value: 4.0)),
        Sidecar::OverrideParams.new(path: 'master.resources.requests.memory', value: Google::Protobuf::Value.new(number_value: 4294967296.0)),
        Sidecar::OverrideParams.new(path: 'master.resources.limits.memory', value: Google::Protobuf::Value.new(number_value: 4294967296.0)),
        Sidecar::OverrideParams.new(path: 'master.persistence.size', value: Google::Protobuf::Value.new(string_value: '5Gi')),
        Sidecar::OverrideParams.new(path: 'master.extraFlags', value: Google::Protobuf::Value.new(list_value: Google::Protobuf::ListValue.new(values: [ Google::Protobuf::Value.new(string_value: '--maxmemory-policy volatile-lru') ]))),
        Sidecar::OverrideParams.new(path: 'auth.password', value: Google::Protobuf::Value.new(string_value: 'password'))
      )
    end

    it 'includes correct postgresql dependency' do
      expect(chart.dependencies[1]).to have_attributes(
        name: "postgresql",
        version: dependency_postgresql.version,
        repository_url: dependency_postgresql.repo_url
      )

      overrides = chart.dependencies[1].overrides
      expect(overrides).to contain_exactly(
        Sidecar::OverrideParams.new(path: 'primary.resources.requests.cpu', value: Google::Protobuf::Value.new(number_value: 32.0)),
        Sidecar::OverrideParams.new(path: 'primary.resources.limits.cpu', value: Google::Protobuf::Value.new(number_value: 32.0)),
        Sidecar::OverrideParams.new(path: 'primary.resources.requests.memory', value: Google::Protobuf::Value.new(number_value: 4294967296.0)),
        Sidecar::OverrideParams.new(path: 'primary.resources.limits.memory', value: Google::Protobuf::Value.new(number_value: 4294967296.0)),
        Sidecar::OverrideParams.new(path: 'primary.persistence.size', value: Google::Protobuf::Value.new(string_value: '5Gi')),
        Sidecar::OverrideParams.new(path: 'auth.database', value: Google::Protobuf::Value.new(string_value: 'test_db')),
        Sidecar::OverrideParams.new(path: 'auth.username', value: Google::Protobuf::Value.new(string_value: 'test_user')),
        Sidecar::OverrideParams.new(path: 'auth.password', value: Google::Protobuf::Value.new(string_value: 'test_pass'))
      )
    end
  end
end
