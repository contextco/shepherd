# # frozen_string_literal: true

class DockerImage::ImageValidator::Gitlab
  # note that this only supports tokens and not username/password.
  # this also does not support self hosted GitLab instances (gitlab.com only)
  def initialize(image, tag, credentials = nil)
    @image = image
    @tag = tag
    @credentials = credentials
  end

  def validate_image
    # This is really annoying one to search, one project can have many repositories, we then need to check them all for the tag
    # I have found it more efficient to do a get on the target tag and see if there was a 200 response rather than getting
    # all the tags an checking if the tag is there.
    success, error_message = check_image_existence
    return DockerImage::ImageValidator::ValidationResult.new(valid: false, error_message:) unless success

    success, error_message = check_tag_existence
    return DockerImage::ImageValidator::ValidationResult.new(valid: false, error_message:) unless success

    DockerImage::ImageValidator::ValidationResult.new(valid: true)
  end

  private

  def check_image_existence
    request, uri = repositories_request
    response = execute_request(request, uri)

    case response
    when Net::HTTPSuccess
      @repositories = JSON.parse(response.body)
      [ true, nil ]
    when Net::HTTPUnauthorized
      [ false, @credentials ? "Invalid credentials" : "Unauthorized - image may be private." ]
    when Net::HTTPNotFound
      [ false, "Image not found." ]
    else
      [ false, "Failed to verify image existence (#{response.code} #{response.message})." ]
    end
  end

  def check_tag_existence
    return [ false, "No repositories found." ] unless @repositories&.any?

    @repositories.map { |r| r["id"] }.each do |repo_id|
      request, uri = tag_request(repo_id)
      response = execute_request(request, uri)

      return [ true, nil ] if response&.code == "200"
    end

    [ false, "Tag '#{@tag}' not found in any of the #{@repositories.count} repositories." ]
  end

  def execute_request(request, uri)
    Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
  end

  def tag_request(repo_id)
    uri = URI.parse("https://gitlab.com/api/v4/projects/#{project_path}/registry/repositories/#{repo_id}/tags/#{@tag}")
    request = Net::HTTP::Get.new(uri)
    request["PRIVATE-TOKEN"] = token if token.present?

    [ request, uri ]
  end

  def repositories_request
    uri = URI.parse("https://gitlab.com/api/v4/projects/#{project_path}/registry/repositories")
    request = Net::HTTP::Get.new(uri)
    request["PRIVATE-TOKEN"] = token if token.present?
    request["Accept"] = "application/vnd.docker.distribution.manifest.v2+json"

    [ request, uri ]
  end

  def project_path
    @project_path ||= ERB::Util.url_encode(@image)
  end

  def token
    @token ||= @credentials&.dig(:password)
  end
end
