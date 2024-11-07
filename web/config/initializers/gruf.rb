require "gruf"
$LOAD_PATH.unshift(File.expand_path("gen", Rails.root))

require "service_pb"
require "service_services_pb"
require "sidecar_pb"
require "sidecar_services_pb"

Rails.application.config.to_prepare do
  Gruf.configure do |c|
    c.default_client_host = "localhost:8080"

    c.server_binding_url = "0.0.0.0:50051"
    c.backtrace_on_error = !Rails.env.production?
    c.use_exception_message = !Rails.env.production?

    c.interceptors.use(Gruf::Interceptors::Instrumentation::RequestLogging::Interceptor)
    c.interceptors.use(AuthenticationInterceptor)
  end
end
