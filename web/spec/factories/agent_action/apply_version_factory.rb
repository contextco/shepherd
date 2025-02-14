# frozen_string_literal: true


FactoryBot.define do
  factory :apply_version_action, class: 'AgentAction::ApplyVersion' do
    target_version_id { create(:project_version).id }
    source_version_id { create(:project_version).id }
    status { 'pending' }
  end
end
