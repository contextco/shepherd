
class TeamController < ApplicationController
  def index
    redirect_to root_path if current_user.nil?
  end

  def create
    Team.transaction do
      team = Team.create!(team_params)
      team.users << current_user
    end

    redirect_to root_path
  end

  private

  def team_params
    params.require(:team).permit(:name)
  end
end
