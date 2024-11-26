
class SubscriberController < ApplicationController
  class NotFoundError < StandardError; end

  def index
    @subscribers = current_team.non_dummy_project_subscribers
  end

  def show
    @subscriber = current_team.project_subscribers.find(params[:id])
    @most_recent_published_version = @subscriber.project.published_versions.first
  end

  def new; end

  def create
    @app = current_team.projects.find(subscriber_params[:project_id])
    @app.project_subscribers.create!(subscriber_params)

    flash[:notice] = "Subscriber \"#{subscriber_params[:name]}\"added"
    redirect_to project_subscriber_index_path
  end

  def destroy
    @subscriber = current_team.project_subscribers.find(params[:id])
    @subscriber.destroy!

    flash[:notice] = "Subscriber \"#{subscriber_params[:name]}\" removed"
    redirect_to project_subscriber_index_path
  end

  def client_values_yaml
    helm_repo = current_team.project_subscribers.find(params[:id]).helm_repo
    version = current_team.project_versions.find(params[:project_version_id])

    begin
      file = helm_repo.client_values_yaml(version:)
      raise NotFoundError, "File not found" if file.nil? unless file.present?

      yaml = file.download.string

      response.headers["Cache-Control"] = "no-cache"
      response.headers["Content-Disposition"] = "attachment; filename=#{helm_repo.client_yaml_filename(version:)}"

      render plain: yaml, content_type: "application/x-yaml", layout: false
    rescue NotFoundError => e
      Rails.logger.error("Error loading client_values.yaml: #{e.message}")

      flash[:error] = "File not found"
      redirect_to project_subscriber_path(params[:id])
    end
  end

  private

  def subscriber_params
    params.require(:project_subscriber).permit(:name, :project_id)
  end
end
