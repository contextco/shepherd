# Generated by the protocol buffer compiler.  DO NOT EDIT!
# Source: sidecar.proto for package ''

require 'grpc'
require 'sidecar_pb'

module Sidecar
  class Service

    include ::GRPC::GenericService

    self.marshal_class_method = :encode
    self.unmarshal_class_method = :decode
    self.service_name = 'Sidecar'

    rpc :PublishChart, ::PublishChartRequest, ::PublishChartResponse
    rpc :ValidateChart, ::ValidateChartRequest, ::ValidateChartResponse
  end

  Stub = Service.rpc_stub_class
end
