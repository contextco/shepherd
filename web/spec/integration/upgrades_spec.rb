# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Upgrades' do
  include ClusterHelpers

  # If you are seeing strange behaviour in this test, this line may be a good starting point as "uses_transaction" has some rough edges:
  # https://github.com/rspec/rspec-rails/issues/2598#issuecomment-1109445577
  uses_transaction "requires outside interference"

  let(:subscriber) { create(:project_subscriber) }

  around do |example|
    release_name = install_agent(subscriber)
    wait_for_agent_to_come_online(subscriber)
    example.run
    uninstall_release(release_name)
  end

  it 'upgrades a subscriber' do
    subscriber.project_version
  end
end
