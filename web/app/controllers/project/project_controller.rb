
# in routes this is the application resource
class Project::ProjectController < ApplicationController
  before_action :fetch_application, only: %i[edit update destroy]

  def destroy
    @app.destroy!

    flash[:notice] = "Deployment #{@app.name} deleted"
    redirect_to root_path
  end

  def new; end

  def edit; end

  def update
    unless project_params[:name].match?(/\A[a-z0-9-]+\z/) && project_params[:name].length <= 100
      flash[:error] = "Name must be lower case and contain only letters, numbers, hyphens and be less than 100 characters"
      return render action: :new, status: :unprocessable_entity
    end
    @app.update!(name: params[:name])

    flash[:notice] = "Application #{@app.name} updated"
    redirect_to project_version_path(@app, @app.latest_version)
  end

  def create
    # turn into a form when we have more fields
    unless project_params[:name].match?(/\A[a-z0-9-]+\z/) && project_params[:name].length <= 100
      flash[:error] = "Name must be lower case and contain only letters, numbers, hyphens and be less than 100 characters"
      return render action: :new, status: :unprocessable_entity
    end

    team = current_user.team
    app = nil
    version = nil
    team.transaction do
      app = team.projects.create!(
        name: project_params[:name],
        )
      version = app.project_versions.create!(
        description: project_params[:description],
        version: "0.0.1",
        state: :draft
      )
      app.helm_users.create!(
        name: app.name,
        password: SecureRandom.hex(8)
      )
    end

    flash[:notice] = "Application #{app.name} created"
    redirect_to project_version_path(app, version)
  end

  private

  def project_params
    params.permit(:name, :description)
  end

  def fetch_application
    @app = current_user.team.projects.find(params[:id])
  end
end
