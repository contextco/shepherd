
class HeartbeatController < RpcController
  bind OnPrem::Service

  def heartbeat
    record_heartbeat

    HeartbeatResponse.new
  end

  private

  def record_heartbeat
    current_deployment.transaction do
      container = current_deployment.containers.find_or_create_by!(name: request.message.identity.name)
      container.health_logs.create!(lifecycle_id: request.message.identity.lifecycle_id)
    end
  end
end
