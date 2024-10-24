
class DeploymentController < ApplicationController
  def create
    current_team.deployments.create!(deployment_params)

    flash[:notice] = "Deployment #{deployment_params[:name]} created"
    redirect_to dashboard_index_path
  end

  private

  def deployment_params
    params.require(:deployment).permit(:name)
  end
end
