# frozen_string_literal: true

module DockerImage::ImageValidator
  # TODO: add caching as we will be rate limited by Docker Hub etc.

  ValidationResult = Struct.new(:valid, :error_message, keyword_init: true)

  class << self
    def valid_image?(image_name, credentials = nil)
      url_parser = DockerImage::UrlParser.new(image_name)

      registry = url_parser.registry || "registry.hub.docker.com"
      image = format_image_name(url_parser.image)
      tag = url_parser.tag || "latest" # Default to latest tag, shouldn't happen as we require a tag in the URL

      token, error_message = fetch_auth_token(image, credentials)
      return ValidationResult.new(valid: false, error_message:) if token.nil?

      success, error_message = check_image_existence(registry, image, tag, token)
      return ValidationResult.new(valid: false, error_message:) unless success

      ValidationResult.new(valid: true)
    end

    private

    def format_image_name(image)
      # we presume that the image is official if it doesn't contain a slash
      # official images are stored in the library namespace
      return image if image.include?("/")

      "library/#{image}"
    end

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
end
