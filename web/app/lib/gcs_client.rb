# frozen_string_literal: true

class GCSClient
  @client = nil

  class << self
    def client
      @client ||= ::Google::Cloud::Storage.new
    end

    def onprem_bucket
      client.bucket "onprem-ctx"
    end
  end
end
