
class Project::VersionController < ApplicationController
  before_action :authenticate_user!
  before_action :fetch_application, only: %i[new create show edit update destroy publish unpublish preview_chart]
  before_action :fetch_previous_version, only: %i[new create]
  before_action :check_deployable, only: %i[publish preview_chart]

  def show; end

  def destroy
    @version.destroy!

    flash[:notice] = "Application version #{@version.version} deleted"
    redirect_to root_path
  end

  def new; end

  def create
    error_msg = version_error_msg(@previous_version.version, version_params[:version])
    if error_msg.present?
      flash[:error] = error_msg
      return render :new, status: :unprocessable_entity
    end
    new_version = @previous_version.fork!(version_params)

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

  def preview_chart
    chart_bytes = Chart::Publisher.new(@version).generate

    send_data(chart_bytes, filename: "chart.tar.gz", type: "application/x-gzip")
  end

  private

  def version_params
    params.require(:project_version).permit(:description, :version)
  end

  def version_error_msg(previous_version, candidate_version)
    return "Version must be a semantic version in the form of major.minor.patch" unless candidate_version.match?(/\d+\.\d+\.\d+/)
    return "Version must be greater than the previous version" unless Gem::Version.new(candidate_version) > Gem::Version.new(previous_version)

    nil
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

  def check_deployable
    return if @version.services.any?

    flash[:error] = "No services attached to publish"
    redirect_to version_path
  end
end
