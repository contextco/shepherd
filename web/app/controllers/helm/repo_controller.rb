require "google/cloud/storage"

class Helm::RepoController < ActionController::Base
  before_action :authenticate_request

  def download
    if (filename = sanitize_filename(params[:filename])).nil?
      return render json: { error: "Invalid filename" }, status: :bad_request
    end

    file = @repo.client.file(filename)
    return render json: { error: "Chart not found" }, status: :not_found if file.nil?

    begin
      signed_url = file.signed_url(
        version: :v4,
        expires: 300, # 5 minutes
        query: {
          "response-content-disposition" => "attachment; filename=#{filename}",
          "response-content-type" => "application/x-tar"
        }
      )

      redirect_to signed_url, allow_other_host: true, status: :temporary_redirect
    rescue Google::Cloud::Storage::SignedUrlUnavailable => e
      Rails.logger.error("SignedUrlUnavailable error: #{e.message}")
      render json: { error: "Missing credentials for signed URL" }, status: :internal_server_error
    rescue StandardError => e
      Rails.logger.error("Error generating signed URL: #{e.class}: #{e.message}")
      Rails.logger.error(e.backtrace&.join("\n"))
      render json: { error: "Could not generate download URL" }, status: :internal_server_error
    end
  end

  def index_yaml
    response.headers["Cache-Control"] = "no-cache"

    begin
      file = @repo.client.index_yaml_file
      raise "File not found" if file.nil?

      yaml = file.download.string
      render plain: yaml, content_type: "application/x-yaml"
    rescue StandardError => e
      Rails.logger.error("Error loading index.yaml: #{e.message}")
      render json: { error: "Could not load index.yaml" }, status: :internal_server_error
    end
  end

  def create
    render plain: "This Helm repository is read-only. Charts cannot be uploaded via the API.",
           status: :forbidden
  end

  def destroy
    render plain: "This Helm repository is read-only. Charts cannot be deleted via the API.",
           status: :forbidden
  end

  private

  def authenticate_request
    if request.authorization.nil?
      return render plain: "Authentication required. Use 'helm repo add' with --username and --password flags",
                    status: :unauthorized
    end

    authenticate_with_http_basic do |username, password|
      user = HelmUser.find_by(name: username)
      return render plain: "Invalid credentials", status: :unauthorized if user.nil?

      @repo = user.helm_repo
      return render plain: "Invalid credentials", status: :unauthorized if @repo.name != params[:repo_name]
      return render plain: "Invalid credentials", status: :unauthorized unless @repo.valid_credentials?(username, password)
    end
  end

  def sanitize_filename(filename)
    # Remove any path traversal attempts and restrict to expected format
    return nil unless filename.match?(/^[\w\-\.]+\.tgz$/)

    filename
  end
end
