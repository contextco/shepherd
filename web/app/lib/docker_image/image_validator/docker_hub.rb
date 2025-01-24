# frozen_string_literal: true

class DockerImage::ImageValidator::DockerHub
  def initialize(registry, image, tag, credentials = nil)
    @registry = registry
    @image = image
    @tag = tag
    @credentials = credentials
  end

  def validate_image
    token, error_message = fetch_auth_token(@image, @credentials)
    return DockerImage::ImageValidator::ValidationResult.new(valid: false, error_message:) if token.nil?

    success, error_message = check_image_existence(@registry, @image, @tag, token)
    return DockerImage::ImageValidator::ValidationResult.new(valid: false, error_message:) unless success

    DockerImage::ImageValidator::ValidationResult.new(valid: true)
  end

  private

  def fetch_auth_token(repository, credentials)
    auth_url = "https://auth.docker.io/token?service=registry.docker.io&scope=repository:#{repository}:pull"
    uri = URI.parse(auth_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)

    if credentials
      auth_string = Base64.strict_encode64("#{credentials[:username]}:#{credentials[:password]}")
      request["Authorization"] = "Basic #{auth_string}"
    end

    response = http.request(request)

    case response
    when Net::HTTPSuccess
      [ JSON.parse(response.body)["token"], nil ]
    when Net::HTTPUnauthorized
      [ nil, "Invalid credentials for Docker registry" ]
    else
      [ nil, "Failed to authenticate with Docker registry" ]
    end
  end

  def check_image_existence(registry, repository, tag, token)
    uri = URI.parse("https://#{registry}/v2/#{repository}/manifests/#{tag}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{token}"
    request["Accept"] = "application/vnd.docker.distribution.manifest.v2+json"

    response = http.request(request)

    case response
    when Net::HTTPSuccess
      [ true, nil ]
    when Net::HTTPNotFound
      [ false, "Image not found" ]
    else
      [ false, "Failed to verify image existence" ]
    end
  end
end
