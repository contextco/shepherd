
class SubscriberController < ApplicationController
  class NotFoundError < StandardError; end

  def index
    @project = current_team.projects.find(params[:project_id]) if params[:project_id].present?
    @subscribers = current_team&.subscribers&.non_dummy
  end

  def show
    @subscriber = current_team.subscribers.find(params[:id])
    @most_recent_published_version = @subscriber.project.published_versions.first
  end

  def deploy
    @subscriber = current_team.subscribers.find(params[:id])
    @agent_instance = @subscriber.agent_instances.most_recently_active
    base_version = @subscriber.project_version
    candidate_version = current_team.project_versions.find(params[:project_version_id])

    @version_comparison = base_version.compare(candidate_version)
  end

  def assign_new_version
    @version = current_team.project_versions.find(params[:project_version_id])
    @subscriber = current_team.subscribers.find(params[:id])

    @subscriber.assign_to_new_version!(@version, created_by: current_user)

    flash[:notice] = "#{@subscriber.name} deploying to version #{@version.version}."
    redirect_to subscriber_path(@subscriber)
  end

  def new
    @app = current_team.projects.find(params[:project_id])
    @version = current_team.project_versions.find(params[:version_id])
  end

  def create
    @version = current_team.project_versions.find(subscriber_params[:project_version_id])
    subscriber = @version.subscribers.create!(subscriber_params)
    subscriber.setup_helm_repo!

    flash[:notice] = "Subscriber \"#{subscriber_params[:name]}\"added"
    redirect_to subscribers_path
  end

  def edit
    @subscriber = current_team.subscribers.find(params[:id])
  end

  def destroy
    @subscriber = current_team.subscribers.find(params[:id])
    @subscriber.destroy!

    flash[:notice] = "Subscriber \"#{@subscriber.name}\" removed"
    redirect_to subscribers_path
  end

  def client_values_yaml
    repo_client = current_team.subscribers.find(params[:id]).helm_repo.client
    version = current_team.project_versions.find(params[:project_version_id])

    begin
      file = repo_client.client_values_yaml_file(version)
      raise NotFoundError, "File not found" if file.nil? unless file.present?

      yaml = file.download.string

      response.headers["Cache-Control"] = "no-cache"
      response.headers["Content-Disposition"] = "attachment; filename=#{repo_client.client_values_yaml_filename(version)}"

      render plain: yaml, content_type: "application/x-yaml", layout: false
    rescue NotFoundError => e
      Rails.logger.error("Error loading client_values.yaml: #{e.message}")

      flash[:error] = "File not found"
      redirect_to subscriber_path(params[:id])
    end
  end

  private

  def subscriber_params
    params.require(:project_subscriber).permit(:name, :auth, :project_version_id, :agent)
  end
end
