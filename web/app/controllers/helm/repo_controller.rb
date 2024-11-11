require "google/cloud/storage"

class Helm::RepoController < ApplicationController
  before_action :authenticate_request

  def download
    filename = sanitize_filename(params[:filename])

    bucket = GCSClient.onprem_bucket
    file = bucket.file("#{params[:repo_name]}/#{filename}")

    if file.present?
      send_file file.download.string,
                type: "application/x-tar",
                disposition: "attachment",
                filename:
    else
      render json: { error: "Chart not found" }, status: :not_found
    end
  end

  def index_yaml
    response.headers["Cache-Control"] = "no-cache"

    begin
      file = bucket.file("#{params[:repo_name]}/index.yaml")
      raise "File not found" if file.nil?

      yaml = file.download.string
      render plain: yaml, content_type: "application/x-yaml"
    rescue StandardError => e
      Rails.logger.error("Error loading index.yaml: #{e.message}")
      render json: { error: "Could not load index.yaml" }, status: :internal_server_error
    end
  end

  def create
    render json: {
      message: "This Helm repository is read-only. Charts cannot be uploaded via the API.",
      help: ""
    }, status: :forbidden
  end

  def destroy
    render json: {
      message: "This Helm repository is read-only. Charts cannot be deleted via the API.",
      help: ""
    }, status: :forbidden
  end

  private

  def authenticate_request
    if request.authorization.nil?
      return render plain: "Authentication required. Use 'helm repo add' with --username and --password flags",
                    status: :unauthorized
    end

    authenticate_with_http_basic do |username, password|
      return if valid_credentials?(username, password)

      return render plain: "Invalid credentials", status: :unauthorized
    end
  end

  def valid_credentials?(username, password)
    true
  end

  def sanitize_filename(filename)
    # Remove any path traversal attempts and restrict to expected format
    return nil unless filename.match?(/^[\w\-\.]+\.tgz$/)
    filename
  end

  def bucket
    @bucket ||= GCSClient.onprem_bucket
  end
end
