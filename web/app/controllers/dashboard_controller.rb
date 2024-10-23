
class DashboardController < ApplicationController
  def index
    redirect_to team_index_path if current_user && current_user.team.nil?
  end
end
