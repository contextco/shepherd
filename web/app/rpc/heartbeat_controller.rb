
class HeartbeatController < Gruf::Controllers::Base
  bind OnPrem::Service

  def heartbeat
    HeartbeatResponse.new
  end
end
