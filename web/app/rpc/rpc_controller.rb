# frozen_string_literal: true

class RpcController < Gruf::Controllers::Base
  protected

  def current_deployment
    request.context[:current_deployment]
  end
end
