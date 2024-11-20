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

    if form.invalid?
      flash[:error] = form.errors.full_messages.first
      return redirect_to new_version_dependency_path(@version, name: dependency_params[:name])
    end

    form.create_dependency(@version)
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

  def form
    return @form if defined?(@form)

    dependency_info = Chart::Dependency.from_name!(dependency_params[:name])
    @form = dependency_info.form.new(dependency_params)
  end

  def dependency_params
    params.require(:dependency).permit(:name, :version, :repo_url, configs: {})
  end

  def set_app
    @version = current_team.project_versions.find(params[:version_id]) if params[:version_id].present?
    @dependency = current_team.dependencies.find(params[:id]) if params[:id].present?
    @version ||= @dependency&.project_version
    @app = @version.project
  end
end
