# frozen_string_literal: true

class HelmRepo < ApplicationRecord
  belongs_to :project

  has_many :helm_users, dependent: :destroy
  validates :name, presence: true

  def add_repo_command
    # helm command to add repo
    command = "helm repo add #{name} #{base_url}/repo/#{name} --username #{helm_users.first.name} --password #{helm_users.first.password}"
    command = "#{command} --insecure-skip-tls-verify" if Rails.env.development? || Rails.env.test?

    command
  end

  def pull_chart_command(service:)
    # eventually this will only expose the main chart and not individual chart but for now we can expose any service
    "helm pull #{name}/#{service.name} --untar"
  end

  def install_chart_command(service:)
    "helm install #{service.name} #{name}/#{service.name}"
  end

  def valid_credentials?(name, password)
    helm_users.exists?(name:, password:)
  end

  def index_yaml
    bucket.file("#{name}/index.yaml")
  end

  def file_yaml(filename)
    bucket.file("#{name}/#{filename}")
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
