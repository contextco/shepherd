# frozen_string_literal: true

class HelmRepo < ApplicationRecord
  belongs_to :project_subscriber
  delegate :project, to: :project_subscriber

  has_one :helm_user, dependent: :destroy
  validates :name, presence: true

  after_create :setup_helm_user

  def client
    RepoClient.new(name, helm_user.name)
  end

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
    "helm install -f #{client.client_values_yaml_filename(version)} --create-namespace --namespace #{project_name} #{project_name} #{name}/#{project_name} --version #{version_version}"
  end

  def valid_credentials?(name, password)
    helm_user.name == name && helm_user.password == password
  end

  def public_repo?
    project_subscriber.auth == false
  end

  private

  def setup_helm_user
    create_helm_user!(
      name: SecureRandom.urlsafe_base64(10),
      password: SecureRandom.urlsafe_base64(16)
    )
  end

  def client_values_yaml_path(version:)
    p = project_subscriber&.project || project # remove after migration complete
    "#{repo_name}/#{p.name}-#{version.version}-values.yaml"
  end

  def base_url
    # TODO: this does not belong here
    return "http://localhost:3000" if Rails.env.development? || Rails.env.test?

    "https://app.trustshepherd.com"
  end

  def bucket
    @bucket ||= GCSClient.onprem_bucket
  end
end
