class ApplicationController < ActionController::Base
  layout :set_layout

  before_action :authenticate_user!
  def current_team
    @current_team ||= current_user&.team
  end

  helper_method :current_team

  private

  def set_layout
    if user_signed_in?
      "web_controller"
    else
      "unauthenticated"
    end
  end
end
