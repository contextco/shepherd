
# in routes this is the application resource
class Project::ProjectController < ApplicationController
  before_action :fetch_application, only: %i[edit destroy]

  def index; end

  def destroy
    @app.destroy!

    flash[:notice] = "Deployment #{@app.name} deleted"
    redirect_to root_path
  end

  def new; end

  def edit; end

  def create
    # turn into a form when we have more fields
    unless project_params[:name].match?(/\A[a-z0-9-]+\z/) && project_params[:name].length <= 100
      flash[:error] = "Name must be lower case and contain only letters, numbers, hyphens and be less than 100 characters"
      return render action: :new, status: :unprocessable_entity
    end

    version = current_team.setup_scaffolding!(project_params[:name], project_params[:description])

    flash[:notice] = "Application #{project_params[:name]} created"
    redirect_to version_path(version)
  end

  private

  def project_params
    params.permit(:name, :description)
  end

  def fetch_application
    @app = current_user.team.projects.find(params[:id])
  end
end
