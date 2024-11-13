
class DeploymentController < ApplicationController
  def index
  end

  def show
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
