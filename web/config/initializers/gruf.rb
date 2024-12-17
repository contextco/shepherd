require "gruf"
$LOAD_PATH.unshift(File.expand_path("gen", Rails.root))

require "service_pb"
require "service_services_pb"
require "sidecar_pb"
require "sidecar_services_pb"

Signal.trap("TERM") do
  puts "Received SIGTERM at #{Time.now}"
  puts "Backtrace: #{caller.join("\n")}"
end

Signal.trap("INT") do
  puts "Received SIGINT at #{Time.now}"
  puts "Backtrace: #{caller.join("\n")}"
end

Rails.application.config.to_prepare do
  Gruf.configure do |c|
    c.default_client_host = "localhost:8080"

    c.server_binding_url = "0.0.0.0:50051"
    # c.backtrace_on_error = !Rails.env.production?
    # c.use_exception_message = !Rails.env.production?
    c.backtrace_on_error = true
    c.use_exception_message = true

    c.logger = Logger.new(STDOUT)
    c.logger.level = Logger::DEBUG

    c.interceptors.use(Gruf::Interceptors::Instrumentation::RequestLogging::Interceptor)
    c.interceptors.use(AuthenticationInterceptor)
  end
end

puts "Configuration complete, server should start soon at #{Time.now}"
