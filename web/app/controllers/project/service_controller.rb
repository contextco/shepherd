
class Project::ServiceController < ApplicationController
  before_action :fetch_application, only: %i[show edit update destroy]

  def show; end

  def destroy
    @service.destroy!

    flash[:notice] = "Application version #{@service.name} deleted"
    redirect_to root_path
  end

  def new; end

  def create; end

  def edit; end

  def update
    # TODO

    flash[:notice] = "Service #{@service.name} updated"
    redirect_to project_version_path(@app, @version)
  end

  private

  def fetch_application
    @app = current_user.team.projects.find(params[:project_id])
    @version = @app.project_versions.find(params[:version_id])
    @service = @version.project_services.find(params[:id])
  end
end
