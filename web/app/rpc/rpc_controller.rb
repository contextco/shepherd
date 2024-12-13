# frozen_string_literal: true

class RpcController < Gruf::Controllers::Base
  protected

  def current_subscriber
    request.context[:current_subscriber]
  end
end
