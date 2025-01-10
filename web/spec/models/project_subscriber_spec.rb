require 'rails_helper'

RSpec.describe ProjectSubscriber, type: :model do
  let(:subscriber) { create(:project_subscriber) }

  describe '#assign_to_new_version!' do
    context 'when moving a subscriber to a new version' do
      let(:new_project_version) { create(:project_version) }
      subject(:assign) { subscriber.assign_to_new_version!(new_project_version) }

      it 'creates a new agent action' do
        expect { assign }.to change { subscriber.apply_version_actions.reload.count }.by(1)
      end

      it 'creates an agent action with the correct version_id' do
        assign
        expect(subscriber.apply_version_actions.last.project_version_id).to eq(new_project_version.id)
      end
    end
  end
end
