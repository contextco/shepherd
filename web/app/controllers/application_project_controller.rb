
class ApplicationProjectController < ApplicationController
  before_action :fetch_application, only: %i[edit update destroy]

  def destroy
    @app.destroy!

    flash[:notice] = "Deployment #{@app.name} deleted"
    redirect_to root_path
  end

  def new; end

  def edit; end

  def update
    @app.update!(name: params[:name])

    flash[:notice] = "Application #{@app.name} updated"
    redirect_to application_version_path(@app, @app.latest_version)
  end

  def create
    team = current_user.team
    app = team.application_projects.create!(
      name: project_application_params[:name],
      )
    version = app.application_project_versions.create!(
      description: project_application_params[:description],
      version: "0.0.1",
      state: :draft
    )

    flash[:notice] = "Application #{app.name} created"
    redirect_to application_version_path(app, version)
  end

  private

  def project_application_params
    params.permit(:name, :description)
  end

  def fetch_application
    @app = current_user.team.application_projects.find(params[:id])
  end
end
