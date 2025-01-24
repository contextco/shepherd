# frozen_string_literal: true

class DockerImage::ImageValidator
  # TODO: add caching as we will be rate limited by Docker Hub etc. need to be careful as results might be stale fast

  ValidationResult = Struct.new(:valid, :error_message, keyword_init: true)

  REGISTRY_MAPPING = {
    "registry.hub.docker.com" => DockerImage::ImageValidator::DockerHub,
    "ghcr.io" => DockerImage::ImageValidator::Github
  }.freeze

  def initialize(image_name, credentials = nil)
    @url_parser = DockerImage::UrlParser.new(image_name)
    @credentials = credentials
  end

  def valid_image?
    validator = REGISTRY_MAPPING[registry]
    error_message = "Cannot do validation for registry: #{registry}"
    return ValidationResult.new(valid: false, error_message:) if validator.nil?

    validator.new(registry, image, tag, @credentials).validate_image
  end

  private

  def format_image_name(image)
    # we presume that the image is official if it doesn't contain a slash
    # official images are stored in the library namespace
    # e.g. nginx -> library/nginx, username/hello-world -> username/hello-world
    return image if image.include?("/")

    "library/#{image}"
  end

  def registry
    # if there is no registry, we assume it's Docker Hub, this is inline with the Docker CLI behaviour
    @registry ||= @url_parser.registry || "registry.hub.docker.com"
  end

  def image
    @image ||= format_image_name(@url_parser.image)
  end

  def tag
    # Default to latest tag, shouldn't happen as we require a tag in the URL
    @tag ||= @url_parser.tag || "latest"
  end
end
