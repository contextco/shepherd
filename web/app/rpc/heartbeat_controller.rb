
class HeartbeatController < RpcController
  bind OnPrem::Service

  def heartbeat
    record_heartbeat

    HeartbeatResponse.new
  end

  private

  def record_heartbeat
    current_subscriber.transaction do
      agent_instance = current_subscriber.agent_instances.find_or_create_by!(name: request.message.identity.name, lifecycle_id: request.message.identity.lifecycle_id)
      agent_instance.event_logs.create!(event_type: :heartbeat)
    end
  end
end
