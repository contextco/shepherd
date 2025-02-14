# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProjectVersion do
  let!(:project) { create(:project, name: "my-testing-project") }
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
           ports: %w[80 443]
    )
  end
  let!(:dependency_redis) { create(:dependency, project_version:, name: 'redis') }
  let!(:dependency_postgresql) { create(:dependency, project_version:, name: 'postgresql', version: '17.x.x', repo_url: 'oci://registry-1.docker.io/bitnamicharts', chart_name: 'postgresql', configs: { cpu_cores: 32, disk_bytes: 5368709120, memory_bytes: 4294967296, db_name: 'test_db', db_user: 'test_user', db_password: 'test_pass' }) }

  let(:mock_client) { double(:sidecar_client) }

  before do
    ENV['USE_LIVE_PUBLISHER'] = 'true'
    allow(SidecarClient).to receive(:client).and_return(mock_client)
  end

  describe '#publish!' do
    let(:response) { double('Response') }

    before do
      allow(mock_client).to receive(:send)
        .with(:publish_chart, kind_of(Sidecar::PublishChartRequest))
        .and_return(response)
    end
  end

  describe '#rpc_chart' do
    subject(:chart) { Chart::Publisher.new(project_version, subscriber: project_subscriber).chart_proto }

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

  describe '#compare' do
    let(:base_version) { create(:project_version, project:) }
    let(:incoming_version) { create(:project_version, project:) }

    context 'with service changes' do
      context 'when a service is added' do
        let!(:incoming_service) do
          create(:project_service,
                 project_version: incoming_version,
                 name: 'web',
                 image: 'nginx:1.20',
                 environment_variables: [ { 'name' => 'ENV', 'value' => 'staging' } ])
        end

        subject(:comparison) { base_version.compare(incoming_version) }

        it 'has one comparison' do
          expect(comparison.comparisons.size).to eq(1)
        end

        it 'detects added service' do
          expect(comparison.has_changes?).to be true

          added = comparison.comparisons.find { |c| c.name == 'web' }
          expect(added).to have_attributes(
                             type: :service,
                             status: :added,
                             changes: be_empty
                           )
        end
      end
    end
  end
end
