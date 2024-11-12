require "google/cloud/storage"

class Helm::RepoController < ApplicationController
  before_action :authenticate_request

  def download
    if (filename = sanitize_filename(params[:filename])).nil?
      return render json: { error: "Invalid filename" }, status: :bad_request
    end

    file = @repo.file_yaml(filename)
    return render json: { error: "Chart not found" }, status: :not_found if file.nil?

    temp_filename = "#{SecureRandom.hex(8)}-#{filename}"
    tempfile = Tempfile.new(temp_filename)
    file.download tempfile.path
    tempfile.rewind

    send_file tempfile.path,
              filename:,
              type: "application/x-tar",
              disposition: "attachment",
              stream: false,
              status: :ok
  ensure
    if tempfile && response.sending?
      tempfile.close
      tempfile.unlink
    end
  end

  def index_yaml
    response.headers["Cache-Control"] = "no-cache"

    begin
      file = @repo.index_yaml
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
    @repo = HelmRepo.find_by(name: params[:repo_name])

    if request.authorization.nil?
      return render plain: "Authentication required. Use 'helm repo add' with --username and --password flags",
                    status: :unauthorized
    end

    authenticate_with_http_basic do |username, password|
      # if the repo does not exist we still say invalid credentials to avoid leaking repo names
      return if @repo&.valid_credentials?(username, password)

      return render plain: "Invalid credentials", status: :unauthorized
    end
  end

  def sanitize_filename(filename)
    # Remove any path traversal attempts and restrict to expected format
    return nil unless filename.match?(/^[\w\-\.]+\.tgz$/)

    filename
  end
end
