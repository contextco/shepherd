
Gruf.configure do |c|
  c.server_binding_url = "0.0.0.0:50051"
  c.backtrace_on_error = true #!Rails.env.production?
  c.use_exception_message = true #!Rails.env.production?

  # Add authentication interceptor if needed
  # c.interceptors.use(
  #   Gruf::Interceptors::Authentication::Basic,
  #   credentials: [ {
  #                   username: ENV.fetch("GRPC_USERNAME", "username"),
  #                   password: ENV.fetch("GRPC_PASSWORD", "password")
  #                 } ]
  # )
end
