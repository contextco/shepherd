
class DocsController < ActionController::Base
  layout "docs_controller"
  protect_from_forgery with: :exception
  before_action :check_password, only: [ :show ]

  SESSION_TIMEOUT = 6.hours.to_i

  def show; end

  def auth
    render layout: "application"
  end

  def verify_password
    subscriber = ProjectSubscriber.find_by_id(params[:id])

    unless subscriber&.authenticate(params[:password])
      flash[:error] = "Invalid password"
      return redirect_to auth_doc_path(params[:id])
    end

    set_session_token(subscriber)
    redirect_to doc_path(params[:id])
  end

  private

  def check_password
    @subscriber = ProjectSubscriber.find_by_id(params[:id])
    return redirect_to auth_doc_path(params[:id]) if @subscriber.nil?
    return true if timestamp_in_unexpired_range && valid_session_token?(@subscriber)

    session.delete(auth_token_key)
    session.delete(auth_timestamp_key)
    redirect_to auth_doc_path(params[:id])
  end

  def generate_session_token(subscriber, timestamp)
    data = "#{subscriber.id}:#{subscriber.password}:#{timestamp}"
    OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, data)
  end

  def set_session_token(subscriber)
    timestamp = Time.current.to_i
    session[auth_token_key] = generate_session_token(subscriber, timestamp)
    session[auth_timestamp_key] = timestamp
  end

  def valid_session_token?(subscriber)
    return false unless auth_token.present? && auth_timestamp.present?

    expected_token = generate_session_token(subscriber, auth_timestamp)
    ActiveSupport::SecurityUtils.secure_compare(auth_token, expected_token)
  end

  def timestamp_in_unexpired_range
    return false if auth_timestamp.nil?

    (Time.current.to_i - auth_timestamp) < SESSION_TIMEOUT
  end

  def auth_timestamp
    session[auth_timestamp_key]
  end

  def auth_token
    session[auth_token_key]
  end

  def auth_timestamp_key
    "subscriber_#{params[:id]}_auth_timestamp"
  end

  def auth_token_key
    "subscriber_#{params[:id]}_auth_token"
  end
end
