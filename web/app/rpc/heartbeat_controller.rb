
class HeartbeatController < RpcController
  bind OnPrem::Service

  def heartbeat
    HeartbeatResponse.new
  end
end
