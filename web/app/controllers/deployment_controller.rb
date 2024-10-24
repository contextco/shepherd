
class DeploymentController < ApplicationController

  def index
    redirect_to team_index_path if current_user && current_user.team.nil?
  end

  def create
    current_team.deployments.create!(deployment_params)

    flash[:notice] = "Deployment #{deployment_params[:name]} created"
    redirect_to root_path
  end

  private

  def deployment_params
    params.require(:deployment).permit(:name)
  end
end
