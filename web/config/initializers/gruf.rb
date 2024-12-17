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

# Process monitoring thread
Thread.new do
  loop do
    begin
      puts "Process status check at #{Time.now}"
      puts "  PID: #{Process.pid}"
      puts "  Parent PID: #{Process.ppid}"
      puts "  Memory: #{`ps -o rss= -p #{Process.pid}`.to_i / 1024} MB"
      puts "  Environment: RAILS_ENV=#{ENV['RAILS_ENV']}, PORT=#{ENV['PORT']}"
      puts "  Current thread count: #{Thread.list.count}"

      # Get process stats if on Linux
      if File.exist?("/proc/#{Process.pid}/stat")
        stat = File.read("/proc/#{Process.pid}/stat").split
        utime = stat[13].to_i
        stime = stat[14].to_i
        puts "  CPU time - User: #{utime}, System: #{stime}"
      end
    rescue => e
      puts "Status check error: #{e.message}"
    end
    sleep 30
  end
end

# Enhanced signal handling
%w[TERM INT QUIT HUP].each do |sig|
  Signal.trap(sig) do
    puts "\n=== Signal Handler Debug ==="
    puts "Received SIG#{sig} at #{Time.now}"
    puts "Current thread count: #{Thread.list.count}"
    puts "Process info:"
    puts "  PID: #{Process.pid}"
    puts "  PPID: #{Process.ppid}"
    puts "Stack trace:"
    puts caller.map { |line| "  #{line}" }.join("\n")
    puts "======================="
  end
end

Rails.application.config.to_prepare do
  Gruf.configure do |c|
    c.default_client_host = "localhost:8080"
    c.server_binding_url = "0.0.0.0:50051"

    # Enable full debugging
    c.backtrace_on_error = true
    c.use_exception_message = true

    # Enhanced logging
    c.logger = Logger.new(STDOUT)
    c.logger.level = Logger::DEBUG
    c.logger.formatter = proc do |severity, datetime, progname, msg|
      thread_id = Thread.current.object_id
      "[#{datetime}] #{severity} [#{thread_id}] #{progname}: #{msg}\n"
    end

    c.health_check_enabled = true

    # Add custom interceptor for startup/shutdown logging
    c.interceptors.use(Class.new(Gruf::Interceptors::ServerInterceptor) do
      def call
        puts "\n=== Request Started ==="
        puts "Time: #{Time.now}"
        puts "Method: #{request.method_key}"
        puts "========================"

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
      # Perform a lightweight operation to keep the process active
      GC.start(full_mark: false, immediate_sweep: true)
    rescue => e
      puts "Keep-alive error: #{e.message}"
    end
    sleep 60
  end
end

puts "Configuration complete, server should start soon at #{Time.now}"
