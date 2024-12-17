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


old_term = Signal.trap('TERM') do
  puts "\n=== Process SIGTERM Handler ==="
  puts "Time: #{Time.now}"
  puts "Process state:"
  puts `ps aux | grep #{Process.pid}`
  begin
    puts "Open files:"
    puts `lsof -p #{Process.pid}`
  rescue => e
    puts "Could not get open files: #{e.message}"
  end
  puts "Call stack:"
  puts caller.join("\n")
  puts "========================="

  # Call original handler if it exists
  old_term.call if old_term.respond_to?(:call)
end

# Enhanced signal handling for INT
old_int = Signal.trap('INT') do
  puts "\n=== Process SIGINT Handler ==="
  puts "Time: #{Time.now}"
  puts "Process state:"
  puts `ps aux | grep #{Process.pid}`
  puts "Call stack:"
  puts caller.join("\n")
  puts "========================="

  # Call original handler if it exists
  old_int.call if old_term.respond_to?(:call)
end

# Process monitoring thread
Thread.new do
  loop do
    begin
      puts "\n=== Process Status at #{Time.now} ==="
      puts "Basic Info:"
      puts "  PID: #{Process.pid}"
      puts "  Parent PID: #{Process.ppid}"
      puts "  Memory: #{`ps -o rss= -p #{Process.pid}`.to_i / 1024} MB"
      puts "  Thread count: #{Thread.list.count}"

      puts "\nEnvironment:"
      puts "  RAILS_ENV: #{ENV['RAILS_ENV']}"
      puts "  PORT: #{ENV['PORT']}"
      puts "  GRPC_SERVER: #{ENV['GRPC_SERVER']}"

      if File.exist?("/proc/#{Process.pid}/stat")
        stat = File.read("/proc/#{Process.pid}/stat").split
        utime = stat[13].to_i
        stime = stat[14].to_i
        puts "\nCPU Usage:"
        puts "  User time: #{utime}"
        puts "  System time: #{stime}"
      end

      puts "\nThread Info:"
      Thread.list.each do |t|
        puts "  Thread #{t.object_id}: #{t.status}"
      end

      puts "========================="
    rescue => e
      puts "Status check error: #{e.message}"
      puts e.backtrace.join("\n")
    end
    sleep 30
  end
end

Rails.application.config.to_prepare do
  Gruf.configure do |c|
    c.default_client_host = "localhost:8080"
    c.server_binding_url = "0.0.0.0:50051"

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

    # Request monitoring interceptor
    c.interceptors.use(Class.new(Gruf::Interceptors::ServerInterceptor) do
      def call
        puts "\n=== gRPC Request at #{Time.now} ==="
        puts "Method: #{request.method_key}"
        puts "Thread ID: #{Thread.current.object_id}"
        puts "Process Info:"
        puts "  PID: #{Process.pid}"
        puts "  Thread count: #{Thread.list.count}"
        puts "========================="

        yield
      end
    end)

    c.interceptors.use(Gruf::Interceptors::Instrumentation::RequestLogging::Interceptor)
    c.interceptors.use(AuthenticationInterceptor)
  end
end

# Keep-alive mechanism
Thread.new do
  loop do
    begin
      puts "Keep-alive heartbeat at #{Time.now}"
    rescue => e
      puts "Keep-alive error: #{e.message}"
      puts e.backtrace.join("\n")
    end
    sleep 60
  end
end

puts "Configuration complete, server should start soon at #{Time.now}"
