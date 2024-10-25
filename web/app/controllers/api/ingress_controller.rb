# frozen_string_literal: true

class Api::IngressController < Api::ApiController
  def heartbeat
    render json: { status: "ok" }
  end
end
