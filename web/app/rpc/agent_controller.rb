
class AgentController < RpcController
  bind OnPrem::Service

  def heartbeat
    record_heartbeat
    HeartbeatResponse.new
  end

  def apply
    action = current_subscriber
      .agent_actions
      .pending
      .order(created_at: :asc)
      .first

    return ApplyResponse.new(action: nil) if action.nil?

    action.completed!
    action.convert_to_proto
  end

  private

  def record_heartbeat
    current_subscriber.transaction do
      agent_instance.event_logs.create!(event_type: :heartbeat)
    end
  end

  def agent_instance
    @agent_instance ||= current_subscriber
                          .agent_instances
                          .find_or_create_by!(name: request.message.identity.name, lifecycle_id: request.message.identity.lifecycle_id)
  end
end
