
class Helm::RepoController < ApplicationController
  def download
    filename = params[:filename]

    bucket = GCSClient.onprem_bucket
    file = bucket.file("sidecar/#{filename}")

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
      file = bucket.file("sidecar/index.yaml")
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

  def bucket
    @bucket ||= GCSClient.onprem_bucket
  end
end
