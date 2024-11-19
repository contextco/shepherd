# frozen_string_literal: true

class HelmRepo < ApplicationRecord
  belongs_to :project

  has_one :helm_user, dependent: :destroy
  validates :name, presence: true

  def repo_name
    # name is not necessarily unique so we need to include the user name which is SecureRandom
    "#{name}-#{helm_user.name}"
  end

  def add_repo_command
    # helm command to add repo
    command = "helm repo add #{name} #{base_url}/repo/#{name} --username #{helm_user.name} --password #{helm_user.password}"
    command = "#{command} --insecure-skip-tls-verify" if Rails.env.development? || Rails.env.test?

    command
  end

  def pull_chart_command
    "helm pull #{name}/#{project.name} --untar"
  end

  def install_chart_command(version:)
    version_version = version.version
    project_name = project.name
    "helm install -f #{version.client_yaml_filename} #{project_name} #{name}/#{project_name} --version #{version_version}"
  end

  def valid_credentials?(name, password)
    helm_user.name == name && helm_user.password == password
  end

  def index_yaml
    bucket.file("#{repo_name}/index.yaml")
  end

  def client_values_yaml(version:)
    bucket.file(version.client_values_yaml_path)
  end

  def file_yaml(filename)
    bucket.file("#{repo_name}/#{filename}")
  end

  private

  def base_url
    # TODO: this does not belong here
    return "http://localhost:3000" if Rails.env.development? || Rails.env.test?

    "https://vpc.context.ai"
  end

  def bucket
    @bucket ||= GCSClient.onprem_bucket
  end
end
