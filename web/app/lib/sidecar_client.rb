# frozen_string_literal: true

class SidecarClient
  @client = nil

  class << self
    def client
      @client ||= ::Gruf::Client.new(service: Sidecar)
    end
  end
end
