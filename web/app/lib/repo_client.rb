# frozen_string_literal: true

class RepoClient
  def initialize(repo_name, helm_user_name)
    @repo_name = repo_name
    @helm_user_name = helm_user_name
  end

  def internal_repo_name
    "#{repo_name}-#{helm_user_name}"
  end

  def chart_filename(version)
    "#{version.project.name}-#{version.version}.tgz"
  end

  def chart_file(version)
    file(chart_filename(version))
  end

  def index_yaml_file
    file("index.yaml")
  end

  def client_values_yaml_file(version)
    file(client_values_yaml_filename(version))
  end

  def client_values_yaml_filename(version)
    "#{version.project.name}-#{version.version}-values.yaml"
  end

  def file(filename)
    bucket.file("#{internal_repo_name}/#{filename}")
  end

  private

  attr_reader :client, :repo_name, :helm_user_name

  def bucket
    GCSClient.onprem_bucket
  end
end
