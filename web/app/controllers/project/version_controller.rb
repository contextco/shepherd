
class Project::VersionController < ApplicationController
  before_action :authenticate_user!
  before_action :fetch_application, only: %i[new create show edit update destroy publish unpublish]
  before_action :fetch_previous_version, only: %i[new create]

  def show; end

  def destroy
    @version.destroy!

    flash[:notice] = "Application version #{@version.version} deleted"
    redirect_to root_path
  end

  def new; end

  def create
    new_version = @app.project_versions.new(version_params)

    if @previous_version.version_integer >= new_version.version_integer
      flash[:error] = "Version must be greater than the previous version V#{@previous_version.version}"
      @previous_version = new_version
      return render :new, status: :unprocessable_entity
    end

    ProjectVersion.transaction do
      new_version.save!
      @previous_version.services.each do |service|
        service = service.dup
        service.project_version = new_version
        service.save!
      end
    end

    flash[:notice] = "Application version created"
    redirect_to version_path(new_version)
  end

  def update
    @version.update!(description: params[:description])

    flash[:notice] = "Application version updated"
    redirect_to version_path(@version)
  end

  def edit; end

  def publish
    if @version.services.empty?
      flash[:error] = "No services attached to publish"
      return redirect_to version_path
    end

    @version.building!
    @version.services.each do |service|
      unless service.publish_chart
        @version.draft!
        flash[:error] = "Failed to publish service #{service.name}"
        return redirect_to version_path
      end
    end
    @version.published!

    flash[:notice] = "Application version published"
    redirect_to version_path(@version)
  end

  def unpublish
    # we should include validations here to ensure there are no attached deployments and perhaps a warning
    @version.draft!
    # we will need to update the repo to either remove the helm chart or deprecate it

    # Also need to make attached services not editable

    flash[:notice] = "Application version unpublished"
    redirect_to version_path(@version)
  end

  private

  def version_params
    params.require(:project_version).permit(:description, :patch_version, :minor_version, :major_version)
  end

  def fetch_application
    @version = current_team.project_versions.find(params[:id]) if params[:id].present?
    @app = @version&.project || current_team.projects.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Application not found"
    redirect_to root_path
  end

  def fetch_previous_version
    @previous_version = @app.project_versions.order(created_at: :desc).first
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "No previous version found"
    redirect_to root_path
  end
end
