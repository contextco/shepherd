# require "gruf"
# $LOAD_PATH.unshift(File.expand_path("gen", Rails.root))
#
# require "service_pb"
# require "service_services_pb"
# require "sidecar_pb"
# require "sidecar_services_pb"
#
# %w[TERM INT QUIT HUP].each do |sig|
#   Signal.trap(sig) do
#     puts "Received SIG#{sig} at #{Time.now}"
#     puts "Backtrace: #{caller.join("\n")}"
#   end
# end
#
# Rails.application.config.to_prepare do
#   Gruf.configure do |c|
#     c.default_client_host = "localhost:8080"
#
#     c.server_binding_url = "0.0.0.0:50051"
#     # c.backtrace_on_error = !Rails.env.production?
#     # c.use_exception_message = !Rails.env.production?
#     c.backtrace_on_error = true
#     c.use_exception_message = true
#
#     c.logger = Logger.new(STDOUT)
#     c.logger.level = Logger::DEBUG
#     c.health_check_enabled = true
#
#     c.interceptors.use(Gruf::Interceptors::Instrumentation::RequestLogging::Interceptor)
#     c.interceptors.use(AuthenticationInterceptor)
#   end
# end
#
# puts "Configuration complete, server should start soon at #{Time.now}"

require "gruf"
$LOAD_PATH.unshift(File.expand_path("gen", Rails.root))

require "service_pb"
require "service_services_pb"
require "sidecar_pb"
require "sidecar_services_pb"

puts "Initializing gruf server at #{Time.now}"

require "grpc/health/checker"
require "grpc/health/v1/health_services_pb"

class HealthCheckService < Grpc::Health::V1::Health::Service
  def check(health_check_request, _call)
    Grpc::Health::V1::HealthCheckResponse.new(
      status: Grpc::Health::V1::HealthCheckResponse::ServingStatus::SERVING
    )
  end
end

Rails.application.config.to_prepare do
  Gruf.configure do |c|
    c.default_client_host = ENV["GRUF_DEFAULT_CLIENT_HOST"] || "localhost:8080"
    c.server_binding_url = ENV["GRUF_SERVER_BINDING_URL"] || "0.0.0.0:50051"

    # Enable debugging
    c.backtrace_on_error = true
    c.use_exception_message = true

    # Enhanced logging
    c.logger = Logger.new(STDOUT)
    c.logger.level = Logger::DEBUG
    c.logger.formatter = proc do |severity, datetime, progname, msg|
      thread_id = Thread.current.object_id
      "[#{datetime}] #{severity} [#{thread_id}] #{progname}: #{msg}\n"
    end

    c.interceptors.use(Gruf::Interceptors::Instrumentation::RequestLogging::Interceptor)
    c.interceptors.use(AuthenticationInterceptor)

    c.server_options[:services] = [ HealthCheckService.new ]

    $stdout.sync = true
  end
end

puts "Configuration complete, server should start soon at #{Time.now}"
