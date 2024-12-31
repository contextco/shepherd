class Dependency < ApplicationRecord
  validate :name_is_known, :repo_url_is_known

  belongs_to :project_version
  has_one :project, through: :project_version

  def name_is_known
    return if info.present?

    errors.add(:name, "Unknown dependency: #{name}")
  end

  def repo_url_is_known
    # for backwards compatibility, to do remove after I do the next prod delete
    return if repo_url == "oci://registry-1.docker.io"
    return if info&.repository == repo_url

    errors.add(:repo_url, "Invalid repository URL for dependency #{name}")
  end

  def info
    @info ||= Chart::Dependency.from_name(name)
  end

  def human_visible_version
    "v#{info.human_visible_version(configs["app_version"])}" if configs["app_version"].present?
  end

  delegate :human_visible_name, :icon, :form_component, to: :info
end
