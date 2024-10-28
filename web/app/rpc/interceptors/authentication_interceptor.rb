
class Interceptors::AuthenticationInterceptor < Gruf::Interceptors::ServerInterceptor
  def call
    result = yield

    puts result

    if result.metadata["authorization"] != "Bearer mykey"
      raise Gruf::Error.new(
        Gruf::Status.new(
          code: Gruf::StatusCodes::UNAUTHENTICATED,
          details: "You are not authorized to access this method"
       )
      )
    end
  end
end
