class DependenciesController < ApplicationController
  before_action :set_app
  def new
    @dependencies = @version.eligible_dependencies
    @dependency = @version.dependencies.build
  end

  def create
    if @version.dependencies.exists?(name: dependency_params[:name])
      flash[:error] = "Dependency #{dependency_params[:name]} already exists"
      return redirect_to version_path(@version)
    end

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
