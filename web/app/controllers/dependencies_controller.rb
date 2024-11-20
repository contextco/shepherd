class DependenciesController < ApplicationController
  before_action :set_app
  def new
    @dependency_info = Chart::Dependency.from_name!(params[:name])
    @dependency_instance = @version.dependencies.build
  end

  def index
    @dependencies = @version.eligible_dependencies
  end

  def create
    if @version.dependencies.exists?(name: dependency_params[:name])
      flash[:error] = "Dependency #{dependency_params[:name]} already exists"
      return redirect_to version_path(@version)
    end

    @version.dependencies.create!(**dependency_params)
    redirect_to version_path(@version)
  end

  def edit
    @dependency = @version.dependencies.find(params[:id])
  end

  def destroy
    @version.dependencies.find(params[:id]).destroy
    redirect_to version_path(@version)
  end

  private

  def dependency_params
    # TODO: make this into a form
    params.require(:dependency).permit(:name, :version, :repo_url, configs: {})
  end

  def set_app
    @version = current_team.project_versions.find(params[:version_id]) if params[:version_id].present?
    @dependency = current_team.dependencies.find(params[:id]) if params[:id].present?
    @version ||= @dependency&.project_version
    @app = @version.project
  end
end
