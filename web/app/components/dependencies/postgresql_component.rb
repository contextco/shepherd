# frozen_string_literal: true

class Dependencies::PostgresqlComponent < DependenciesComponent
  def db_connection_string
    return if dependency_instance&.dependency.nil?

    dependency = dependency_instance.dependency
    password = dependency.configs["db_password"]
    username = dependency.configs["db_user"]
    db_name = dependency.configs["db_name"]
    host = "#{dependency.project.name}-postgresql"

    "postgresql://#{username}:#{password}@#{host}/#{db_name}"
  end

  def enforces_version_consistency?
    # fields like name cannot change between versions, but can be updated if this is the first version and is unpublished
    return true if disabled

    previous_version = version.previous_version
    return false if previous_version.nil?

    # if previous version has a dependency with the same name, then we can't update
    return true if previous_version.dependencies.any? { |d| d.info.name == dependency_instance.dependency.info.name }

    false
  end
end
