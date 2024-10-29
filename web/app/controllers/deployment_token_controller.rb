
class DeploymentTokenController < ApplicationController
  def index
    @deployment = current_team.deployments.find(params[:deployment_id])
  end
  def destroy
    deployment.tokens.find(params[:id]).destroy!

    flash[:notice] = "Token deleted"
    redirect_to deployment_token_index_path(deployment)
  end

  def create
    deployment.tokens.create!

    flash[:notice] = "Token created"
    redirect_to deployment_token_index_path(deployment)
  end

  private

  def deployment
    @deployment ||= Deployment.find(params[:deployment_id])
  end
end
