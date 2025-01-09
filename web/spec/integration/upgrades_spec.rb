# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Upgrades' do
  include ClusterHelpers

  # If you are seeing strange behaviour in this test, this line may be a good starting point as "uses_transaction" has some rough edges:
  # https://github.com/rspec/rspec-rails/issues/2598#issuecomment-1109445577
  uses_transaction "requires outside interference"

  let(:version) { create(:project_version, version: '0.0.1', agent: :full) }
  let(:nginx) { create(:nginx_service, project_version: version) }
  let(:subscriber) { create(:project_subscriber, project_version: version) }

  around(:context) do |example|
    nginx
    ENV['USE_LIVE_PUBLISHER'] = 'true'

    release_name = install_agent(subscriber)
    wait_for_agent_to_come_online(subscriber)
    example.run
    uninstall_release(release_name)

    ENV['USE_LIVE_PUBLISHER'] = nil
  end

  it 'upgrades a subscriber', uses_transactional_fixtures: false, truncate: true do
    new_version = version.fork!(version: '0.0.2')
    new_version
      .services
      .find_by(name: 'nginx')
      .update!(image: 'nginx:1.27-alpine')

    new_version.published!

    subscriber.update!(project_version: new_version)

    sleep(1000)
  end
end
