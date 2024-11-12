
class Project::ServiceController < ApplicationController
  before_action :fetch_application, only: %i[show edit update destroy new create]

  def show; end

  def destroy
    @service.destroy!

    flash[:notice] = "Application version #{@service.name} deleted"
    redirect_to project_version_path(@app, @version)
  end

  def new; end

  def create
    unless form.valid?
      flash.now[:error] = form.errors.full_messages.first
      @service = form.build_service
      return render :new, status: :unprocessable_entity
    end

    @service = form.create_service(@version)

    flash[:notice] = "Service #{@service.name} created"
    redirect_to project_service_path(@service)
  end

  def edit; end

  def update
    unless form.valid?
      flash[:error] = form.errors.full_messages.first
      @service = form.build_service
      return render :edit, status: :unprocessable_entity
    end

    form.update_service(@service)

    flash[:notice] = "Service #{@service.name} updated"
    redirect_to project_service_path(@service)
  end

  private

  def form
    @form ||= Service::Form.new(params[:service_form])
  end

  def fetch_application
    @version = current_team.project_versions.find(params[:version_id]) if params[:version_id].present?
    @service = current_team.services.find(params[:id]) if params[:id].present?
    @version = @service&.project_version || current_team.project_versions.find(params[:project_version_id])
    @app = @version&.project
  end
end
