
class DeploymentController < ApplicationController
  def index
    flash[:error] = "You need to create a team first"
    redirect_to team_index_path if current_user && current_user.team.nil?
  end

  def show
    redirect_to team_index_path if current_user && current_user.team.nil?

    @deployment = current_team.deployments.find(params[:id])
  end

  def destroy
    deployment = current_team.deployments.find(params[:id])
    deployment.destroy!

    flash[:notice] = "Deployment #{deployment.name} deleted"
    redirect_to root_path
  end

  def create
    current_team.deployments.create!(deployment_params)

    flash[:notice] = "Deployment #{deployment_params[:name]} created"
    redirect_to root_path
  end

  def settings
    @deployment = current_team.deployments.find(params[:id])
  end

  private

  def deployment_params
    params.require(:deployment).permit(:name)
  end
end
