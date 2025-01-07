require 'rails_helper'

RSpec.describe ProjectSubscriber, type: :model do
  let(:subscriber) { create(:project_subscriber) }

  describe 'callbacks' do
    context 'when moving a subscriber to a new version' do
      let(:new_project_version) { create(:project_version) }

      it 'creates a new agent action' do
        expect { subscriber.update!(project_version: new_project_version) }.to change { subscriber.apply_version_actions.reload.count }.by(1)
      end

      it 'creates an agent action with the correct version_id' do
        subscriber.update!(project_version: new_project_version)
        expect(subscriber.apply_version_actions.last.project_version_id).to eq(new_project_version.id)
      end
    end
  end
end
