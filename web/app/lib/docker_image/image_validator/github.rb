# frozen_string_literal: true

class DockerImage::ImageValidator::Github
  def initialize(registry, image, tag, credentials = nil)
    @registry = registry # this really always has to be ghcr.io
    @image = image
    @tag = tag
    @credentials = credentials
  end

  def validate_image
    token, error_message = fetch_auth_token
    return DockerImage::ImageValidator::ValidationResult.new(valid: false, error_message:) if token.nil?

    success, error_message = check_image_existence(token)
    return DockerImage::ImageValidator::ValidationResult.new(valid: false, error_message:) unless success

    DockerImage::ImageValidator::ValidationResult.new(valid: true)
  end

  private

  def fetch_auth_token
    auth_url = "https://#{@registry}/token?scope=repository:#{@image}:pull"
    uri = URI.parse(auth_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)

    if @credentials
      request["Authorization"] = "Bearer #{@credentials[:password]}"
    end

    response = http.request(request)

    case response
    when Net::HTTPSuccess
      [JSON.parse(response.body)["token"], nil]
    when Net::HTTPUnauthorized
      [nil, @credentials ? "Invalid credentials" : "Failed to get token for repository"]
    else
      [nil, "Failed to authenticate with registry"]
    end
  end


  def check_image_existence(token)
    uri = URI.parse("https://#{@registry}/v2/#{@image}/manifests/#{@tag}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{token}"
    request["Accept"] = "application/vnd.docker.distribution.manifest.v2+json"

    response = http.request(request)

    case response
    when Net::HTTPSuccess
      [true, nil]
    when Net::HTTPUnauthorized
      [false, @credentials ? "Invalid credentials" : "Unauthorized - image may be private."]
    when Net::HTTPNotFound
      [false, "Image not found."]
    else
      [false, "Failed to verify image existence."]
    end
  end
end
