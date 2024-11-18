# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChartPublisher do
  describe '#validate_chart!' do
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
    let(:client) { double('client') }
    let(:resp) { double('resp', errors: [], valid: true) }

    before do
      allow(SidecarClient).to receive(:client).and_return(client)
      allow(client).to receive(:send).and_return(resp)
    end

    it 'calls validate_chart with correct parameters' do
      expect(client).to receive(:send) do |method, request|
        expect(method).to eq(:validate_chart)
        expect(request.chart).to eq(project_version.rpc_chart)
        resp
      end

      ChartPublisher.new(project_version.rpc_chart, project_version).validate_chart!
    end

    context 'when chart is invalid' do
      let(:resp) { double('resp', errors: [ 'Invalid configuration' ], valid: false) }

      it 'raises ChartValidationError' do
        expect { ChartPublisher.new(project_version.rpc_chart, project_version).validate_chart! }.to raise_error(ChartPublisher::ChartValidationError)
      end

      it 'logs validation errors' do
        expect(Rails.logger).to receive(:info).with("SideCar Validation Error: Invalid configuration")
        expect { ChartPublisher.new(project_version.rpc_chart, project_version).validate_chart! }.to raise_error(ChartPublisher::ChartValidationError)
      end
    end
  end
end
