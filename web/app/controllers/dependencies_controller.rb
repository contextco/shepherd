class DependenciesController < ApplicationController
  before_action :set_app
  def new
    @dependencies = Chart::Dependency.all
    @dependency = @version.dependencies.build
  end

  def create
    @version.dependencies.create!(**dependency_params)
    redirect_to version_path(@version)
  end

  private

  def dependency_params
    params.require(:dependency).permit(:name, :version, :repo_url)
  end

  def set_app
    @version = current_team.project_versions.find(params[:version_id])
    @app = @version.project
  end
end
