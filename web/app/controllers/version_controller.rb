
class VersionController < ApplicationController

  before_action :fetch_application, only: %i[show edit update destroy]

  def show; end

  def destroy
    @version.destroy!

    flash[:notice] = "Application version #{@version.version} deleted"
    redirect_to root_path
  end

  def new; end

  def create; end

  def update
    @app.update!(name: project_application_params[:name])
    @version.update!(description: project_application_params[:description])

    flash[:notice] = "Application version updated"
    redirect_to application_version_path(@app, @version)
  end

  def edit; end

  def release
    raise "Not implemented"
  end

  private

  def fetch_application
    @app = current_user.team.application_projects.find(params[:application_id])
    @version = @app.application_project_versions.find(params[:id])
  end

  def project_application_params
    params.permit(:name, :description)
  end
end
