# frozen_string_literal: true

class DockerImage::UrlParser
  # Known registries help distinguish between registry and username
  KNOWN_REGISTRIES = %w[registry.hub.docker.com docker.io ghcr.io quay.io gcr.io registry.gitlab.com]

  DOCKER_IMAGE_REGEX = %r{
    ^(?:(?<registry>(?:#{KNOWN_REGISTRIES.join('|')})/))? # Only match known registries
    (?<image>                  # Image name is required
      (?:[^/]+/)*             # Optional organization/user
      [^/:]+                  # Repository name
    )
    (?::(?<tag>[^/]+))?$      # Optional tag/version
  }x

  attr_reader :registry, :image, :tag

  def initialize(image_url)
    @image_url = image_url.to_s.strip
    parse
  end

  def parse
    match = DOCKER_IMAGE_REGEX.match(@image_url)
    raise InvalidDockerImageURLError, "Invalid Docker image URL: #{@image_url}" unless match

    @registry = match[:registry]&.chomp("/")
    @image = match[:image]
    @tag = match[:tag]

    validate_components!
  end

  def to_s(with_tag: true)
    without_tag = [ @registry, @image ].compact.join("/")
    return without_tag unless with_tag && @tag

    "#{without_tag}:#{@tag}"
  end

  class InvalidDockerImageURLError < StandardError; end

  private

  def validate_components!
    # Check for common invalid patterns
    if @image_url.include?("::")
      raise InvalidDockerImageURLError, "Invalid tag format: double colon"
    end

    if @image_url.count(":") > 1
      raise InvalidDockerImageURLError, "Invalid format: multiple colons"
    end

    if @image_url.end_with?("/")
      raise InvalidDockerImageURLError, "Invalid format: trailing slash"
    end

    if @image_url.start_with?("/")
      raise InvalidDockerImageURLError, "Invalid format: leading slash"
    end

    if @registry && !KNOWN_REGISTRIES.include?(@registry)
      raise InvalidDockerImageURLError, "Invalid or unknown registry: #{@registry}"
    end

    # Validate tag if present
    if @image_url.include?(":") && @tag.nil?
      raise InvalidDockerImageURLError, "Invalid tag format"
    end
  end
end
