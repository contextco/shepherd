require "gruf"
$LOAD_PATH.unshift(File.expand_path("gen", Rails.root))

require "service_pb"
require "service_services_pb"

Gruf.configure do |c|
  c.server_binding_url = "0.0.0.0:50051"
  c.backtrace_on_error = !Rails.env.production?
  c.use_exception_message = !Rails.env.production?
end
