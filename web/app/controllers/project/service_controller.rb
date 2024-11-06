
class Project::ServiceController < ApplicationController
  before_action :fetch_application, only: %i[show edit update destroy new create]

  def show; end

  def destroy
    @service.destroy!

    flash[:notice] = "Application version #{@service.name} deleted"
    redirect_to root_path
  end

  def new; end

  def create
    unless form.valid?
      flash[:error] = form.errors.full_messages.first
      return render action: :new, status: :unprocessable_entity
    end

    @service = form.create_service(@version)

    flash[:notice] = "Service #{@service.name} created"
    redirect_to project_version_path(@app, @version)
  end

  def edit; end

  def update
    unless form.valid?
      flash[:error] = form.errors.full_messages.first
      return render action: :edit, status: :unprocessable_entity
    end

    form.update_service(@service)

    flash[:notice] = "Service #{@service.name} updated"
    redirect_to project_version_path(@app, @version)
  end

  private

  def form
    @form ||= Service::Form.new(params[:project_service])
  end

  def fetch_application
    @app = current_user.team.projects.find(params[:project_id])
    @version = @app.project_versions.find(params[:version_id])
    @service = @version.project_services.find(params[:id]) if params[:id].present?
  end
end
