
class Project::ServiceController < ApplicationController
  before_action :fetch_application, only: %i[show edit update destroy new create]

  def show; end

  def destroy
    @service.destroy!

    flash[:notice] = "Application version #{@service.name} deleted"
    redirect_to version_path(@service.project_version)
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
    redirect_to version_path(@version)
  end

  def edit
    @disabled = @version.published?
  end

  def update
    if @version.published?
      flash[:error] = "Service #{@service.name} cannot be updated"
      return redirect_to edit_project_service_path(@version)
    end

    unless form.valid?
      flash[:error] = form.errors.full_messages.first
      @service = form.build_service
      return render :edit, status: :unprocessable_entity
    end

    form.update_service(@service)

    flash[:notice] = "Service #{@service.name} updated"
    redirect_to version_path(@version)
  end

  def validate_image
    @validation = form.validate_image
  end

  private

  def form
    @form ||= Service::Form.new(params[:service_form])
  end

  def fetch_application
    @service = current_team.services.find(params[:id]) if params[:id].present?
    @version = @service&.project_version || current_team.project_versions.find(params[:version_id])
    @app = @version&.project
  end
end
