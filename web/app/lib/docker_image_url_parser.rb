# frozen_string_literal: true

class DockerImageUrlParser
  DOCKER_IMAGE_REGEX = %r{
    ^(?:(?<registry>[^/]+)/)?  # Optional registry
    (?<image>                  # Image name is required
      (?:[^/]+/)*              # Optional organization/user
      [^/:]+                   # Repository name
    )
    (?::(?<tag>[^/]+))?$       # Optional tag/version
  }x

  attr_reader :registry, :image, :tag

  def initialize(image_url)
    @image_url = image_url.to_s.strip
    parse
  end

  def parse
    match = DOCKER_IMAGE_REGEX.match(@image_url)
    raise InvalidDockerImageURLError, "Invalid Docker image URL: #{@image_url}" unless match

    @registry = match[:registry]
    @image = match[:image]
    @tag = match[:tag] || "latest"
  end

  def to_s
    [ @registry, @image, @tag ].compact.join("/")
  end

  class InvalidDockerImageURLError < StandardError; end
end
