# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Comparisons::Version do
  let(:project) { create(:project) }
  let(:base_version) { create(:project_version, project:) }
  let(:incoming_version) { create(:project_version, project:) }

  describe 'VersionComparison' do
    describe '.from' do
      context 'with no changes' do
        let(:base_service) { create(:project_service, project_version: base_version, name: 'web') }
        let(:incoming_service) do
          create(:project_service,
                 project_version: incoming_version,
                 name: 'web',
                 image: base_service.image,
                 environment_variables: base_service.environment_variables)
        end

        let(:base_dependency) { create(:dependency, project_version: base_version, name: 'redis') }
        let(:incoming_dependency) do
          create(:dependency,
                 project_version: incoming_version,
                 name: 'redis',
                 configs: base_dependency.configs)
        end

        before do
          base_service && incoming_service
          base_dependency && incoming_dependency
        end

        it 'returns empty comparisons when no changes exist' do
          comparison = described_class::VersionComparison.from(base_version, incoming_version)
          expect(comparison.has_changes?).to be false
          expect(comparison.comparisons).to be_empty
        end
      end

      context 'with service changes' do
        context 'when a service is added' do
          let!(:incoming_service) { create(:project_service, project_version: incoming_version, name: 'new-service') }

          it 'detects added service' do
            comparison = described_class::VersionComparison.from(base_version, incoming_version)
            expect(comparison.has_changes?).to be true

            added = comparison.comparisons.find { |c| c.name == 'new-service' }
            expect(added).to have_attributes(
                               type: :service,
                               status: :added,
                               changes: be_empty
                             )
          end
        end

        context 'when a service is removed' do
          let!(:base_service) do
            create(:project_service,
                   project_version: base_version,
                   name: 'removed-service')
          end

          it 'detects removed service' do
            comparison = described_class::VersionComparison.from(base_version, incoming_version)
            expect(comparison.has_changes?).to be true

            removed = comparison.comparisons.find { |c| c.name == 'removed-service' }
            expect(removed).to have_attributes(
                                 type: :service,
                                 status: :removed,
                                 changes: be_empty
                               )
          end
        end

        context 'when a service is modified' do
          let(:base_service) { create(:project_service, project_version: base_version, name: 'web', image: 'nginx:1.19', environment_variables: [ { 'name' => 'ENV', 'value' => 'prod' } ]) }

          let(:incoming_service) do
            create(:project_service,
                   project_version: incoming_version,
                   name: 'web',
                   image: 'nginx:1.20',
                   environment_variables: [ { 'name' => 'ENV', 'value' => 'staging' } ])
          end

          before do
            base_service && incoming_service
          end

          it 'detects modified service with correct changes' do
            comparison = described_class::VersionComparison.from(base_version, incoming_version)
            expect(comparison.has_changes?).to be true

            modified = comparison.comparisons.find { |c| c.name == 'web' }
            expect(modified).to have_attributes(
                                  type: :service,
                                  status: :modified
                                )

            changes = modified.changes
            expect(changes).to contain_exactly(
                                 have_attributes(
                                   field: 'Image',
                                   old_value: 'nginx:1.19',
                                   new_value: 'nginx:1.20'
                                 ),
                                 have_attributes(
                                   field: 'Environment Variable ENV',
                                   old_value: 'prod',
                                   new_value: 'staging'
                                 )
                               )
          end
        end
      end

      context 'with dependency changes' do
        context 'when a dependency is added' do
          let!(:incoming_dependency) { create(:dependency, project_version: incoming_version, name: 'redis') }

          it 'detects added dependency' do
            comparison = described_class::VersionComparison.from(base_version, incoming_version)
            expect(comparison.has_changes?).to be true

            added = comparison.comparisons.find { |c| c.name == 'redis' }
            expect(added).to have_attributes(
                               type: :dependency,
                               status: :added,
                               changes: be_empty
                             )
          end
        end

        context 'when a dependency is removed' do
          let!(:base_dependency) { create(:dependency, project_version: base_version, name: 'redis') }

          it 'detects removed dependency' do
            comparison = described_class::VersionComparison.from(base_version, incoming_version)
            expect(comparison.has_changes?).to be true

            removed = comparison.comparisons.find { |c| c.name == 'redis' }
            expect(removed).to have_attributes(
                                 type: :dependency,
                                 status: :removed,
                                 changes: be_empty
                               )
          end
        end

        context 'when a dependency is modified' do
          let(:base_dependency) do
            create(:dependency,
                   project_version: base_version,
                   name: 'redis',
                   configs: { 'version' => '6.0' })
          end

          let(:incoming_dependency) do
            create(:dependency,
                   project_version: incoming_version,
                   name: 'redis',
                   configs: { 'version' => '7.0' })
          end

          before do
            base_dependency && incoming_dependency
          end

          it 'detects modified dependency with correct changes' do
            comparison = described_class::VersionComparison.from(base_version, incoming_version)
            expect(comparison.has_changes?).to be true

            modified = comparison.comparisons.find { |c| c.name == 'redis' }
            expect(modified).to have_attributes(
                                  type: :dependency,
                                  status: :modified
                                )

            expect(modified.changes).to contain_exactly(
                                          have_attributes(
                                            field: 'version',
                                            old_value: '6.0',
                                            new_value: '7.0'
                                          )
                                        )
          end
        end
      end
    end

    describe 'ObjectComparison' do
      subject(:comparison) do
        Comparisons::ObjectComparison.new(
          name: 'test',
          type: type,
          status: status,
          changes: []
        )
      end

      context 'with service type' do
        let(:type) { :service }
        let(:status) { :modified }

        it { is_expected.to be_service }
        it { is_expected.not_to be_dependency }
      end

      context 'with dependency type' do
        let(:type) { :dependency }
        let(:status) { :modified }

        it { is_expected.to be_dependency }
        it { is_expected.not_to be_service }
      end

      context 'with different statuses' do
        let(:type) { :service }

        context 'when added' do
          let(:status) { :added }
          it { is_expected.to be_added }
          it { is_expected.not_to be_modified }
          it { is_expected.not_to be_removed }
        end

        context 'when removed' do
          let(:status) { :removed }
          it { is_expected.to be_removed }
          it { is_expected.not_to be_modified }
          it { is_expected.not_to be_added }
        end

        context 'when modified' do
          let(:status) { :modified }
          it { is_expected.to be_modified }
          it { is_expected.not_to be_added }
          it { is_expected.not_to be_removed }
        end
      end
    end
  end
end
