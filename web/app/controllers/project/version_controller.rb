
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
    if @version.services.empty?
      flash[:error] = "No services attached to publish"
      return redirect_to version_path
    end

    @version.publish!

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

  def client_values_yaml
    # this will use the parent chart only and not per service as per here when available
    version = current_team.project_versions.find(params[:id])
    service = version.services.find(params[:service_id])
    helm_repo = service.helm_repo

    response.headers["Cache-Control"] = "no-cache"
    response.headers["Content-Disposition"] = "attachment; filename=#{version.client_yaml_filename}"

    begin
      file = helm_repo.client_values_yaml(service:)
      raise "File not found" if file.nil?

      yaml = file.download.string
      render plain: yaml, content_type: "application/x-yaml", layout: false
    rescue StandardError => e
      Rails.logger.error("Error loading client_values.yaml: #{e.message}")
      render json: { error: "Could not load client_values.yaml" }, status: :internal_server_error, layout: false
    end
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
end
