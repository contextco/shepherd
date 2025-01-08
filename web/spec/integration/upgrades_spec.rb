# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Upgrades' do
  include ClusterHelpers

  let(:subscriber) { create(:project_subscriber) }

  around do |example|
    release_name = install_agent(subscriber)
    example.run
    uninstall_release(release_name)
  end

  it 'upgrades a subscriber' do
    # Hooray!
  end
end
