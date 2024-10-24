
class UserController < ApplicationController
  def index
    redirect_to root_path if current_user.nil?
  end

  def leave_team
    team = current_user.team
    current_user.update!(team: nil)
    team.destroy! if team.users.empty?

    redirect_to team_index_path
  end
end
