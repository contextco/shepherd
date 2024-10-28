
class AuthenticationInterceptor < Gruf::Interceptors::ServerInterceptor
  def call
    authenticate!
    yield
  end

  private

  def authenticate!
    token = Deployment::Token.find_by(token: key_from_metadata)
    fail!(:unauthenticated, "Token not found") unless token

    request.context[:current_deployment] = token.deployment
  end

  def key_from_metadata
    return "" unless request.metadata[:authorization].present?

    request.metadata[:authorization].split(" ").last
  end
end
