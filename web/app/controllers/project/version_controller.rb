
class Project::VersionController < ApplicationController
  before_action :authenticate_user!
  before_action :fetch_application, only: %i[show edit update destroy publish unpublish]

  def show; end

  def destroy
    @version.destroy!

    flash[:notice] = "Application version #{@version.version} deleted"
    redirect_to root_path
  end

  def create
    raise "Not implemented"
  end

  def update
    @version.update!(description: params[:description])

    flash[:notice] = "Application version updated"
    redirect_to project_version_path(@app, @version)
  end

  def edit; end

  def publish
    @version.published!

    # this is where we should call the helm builder sidecar to build the helm chart
    # ideally we should not go straight into published state but rather building state

    flash[:notice] = "Application version published"
    redirect_to project_version_path
  end

  def unpublish
    # we should include validations here to ensure there are no attached deployments and perhaps a warning
    @version.draft!

    flash[:notice] = "Application version unpublished"
    redirect_to project_version_path
  end

  private

  def fetch_application
    @app = current_user.team.projects.find(params[:project_id])
    @version = @app.project_versions.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render status: :forbidden, json: { error: "Access denied" }
  end
end
