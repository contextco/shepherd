# frozen_string_literal: true

class HelmRepo < ApplicationRecord
  belongs_to :project

  has_many :helm_users, dependent: :destroy
  validates :name, presence: true

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

  def bucket
    @bucket ||= GCSClient.onprem_bucket
  end
end
