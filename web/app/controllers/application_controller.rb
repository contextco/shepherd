class ApplicationController < ActionController::Base
  layout "web_controller"
  def current_team
    @current_team ||= current_user&.team
  end
end
