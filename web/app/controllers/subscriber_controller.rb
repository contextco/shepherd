
class SubscriberController < ApplicationController
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

  private

  def subscriber_params
    params.require(:project_subscriber).permit(:name, :project_id)
  end
end
