class Dependency < ApplicationRecord
  validate :name_is_known, :version_is_known, :repo_url_is_known

  def name_is_known
    return if info.present?

    errors.add(:name, "Unknown dependency: #{name}")
  end

  def version_is_known
    return if info&.variants&.map(&:version)&.include?(version)

    errors.add(:version, "Unknown version for dependency #{name}: #{version}")
  end

  def repo_url_is_known
    return if info&.repository == repo_url

    errors.add(:repo_url, "Invalid repository URL for dependency #{name}")
  end

  def info
    @info ||= Chart::Dependency.from_name(name)
  end

  delegate :human_visible_name, :icon, to: :info
end
