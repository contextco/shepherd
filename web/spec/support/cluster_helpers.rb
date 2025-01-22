# frozen_string_literal: true

module ClusterHelpers
  include AgentProto

  def install_agent(subscriber)
    publisher = Chart::Publisher.new(subscriber.project_version, subscriber:)
    req = Sidecar::GenerateAndInstallRequest.new(chart: publisher.chart_proto)

    response = client.send(:generate_and_install, req)

    puts "Starting install with release name: #{response.release_name}"

    response.release_name
  end

  def wait_for_agent_to_come_online(subscriber)
    puts "Starting to wait for agent to come online"
    loop do
      if subscriber.reload.online? && subscriber.heartbeat_logs.most_recent&.project_version_id == subscriber.project_version_id
        puts "Agent is online"
        return
      end
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
