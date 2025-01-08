# frozen_string_literal: true

module ClusterHelpers
  include AgentProto

  def install_agent(subscriber)
    req = Sidecar::GenerateAndInstallRequest.new(
      chart: Sidecar::ChartParams.new(
        name: 'agent-test-service',
        version: '0.1.0',
        services: [ agent_proto_definition(subscriber) ]
      )
    )

    response = client.send(:generate_and_install, req)

    response.release_name
  end

  def wait_for_agent_to_come_online(subscriber)
    loop do
      return if subscriber.reload.online?
      sleep 0.5
    end
  end

  def uninstall_release(release_name)
    client.send(:uninstall, Sidecar::UninstallRequest.new(release_name: release_name))
  end

  def client
    ::Gruf::Client.new(service: Sidecar::SidecarTest)
  end
end
