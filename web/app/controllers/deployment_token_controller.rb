
class DeploymentTokenController < ApplicationController
  def destroy
    deployment.tokens.find(params[:id]).destroy!

    flash[:notice] = "Token deleted"
    redirect_to tokens_deployment_path(deployment)
  end

  def create
    deployment.tokens.create!

    flash[:notice] = "Token created"
    redirect_to tokens_deployment_path(deployment)
  end

  private

  def deployment
    @deployment ||= Deployment.find(params[:deployment_container_id])
  end
end
