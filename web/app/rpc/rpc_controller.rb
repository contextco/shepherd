
class RpcController < ::Gruf::Controllers::Base
  bind ::OnPrem::Service

  def heartbeat(request)
    puts "Received heartbeat request: #{request.inspect}"
    ::HeartbeatResponse.new
  end
end
