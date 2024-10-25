# frozen_string_literal: true

module Api::Concerns::Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate!
  end

  private

  def current_team
    return @current_team if defined? @current_team

    @current_team = current_user&.team
  end

  def current_user
    @current_user ||= User.first # TODO: implement tokens
  end

  def authenticate!
    render json: { error: "Unauthorized" }, status: :unauthorized if current_user.blank?
  end

  def token_from_header
    request.headers["Authorization"]&.split&.last
  end
end
