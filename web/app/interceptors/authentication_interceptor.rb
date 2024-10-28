
class AuthenticationInterceptor < Gruf::Interceptors::ServerInterceptor
  def call
    authenticate!
    yield
  end

  private

  def authenticate!
    token = Deployment::Token.find_by(token: token_from_request_metadata)
    fail!(:unauthenticated, "Token not found") unless token.present?

    request.context[:current_deployment] = token.deployment
  end

  def token_from_request_metadata
    return "" unless request.metadata[:authorization].present?

    request.metadata[:authorization].split(" ").last
  end
end
