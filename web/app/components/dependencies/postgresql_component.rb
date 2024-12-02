# frozen_string_literal: true

class Dependencies::PostgresqlComponent < DependenciesComponent

  def db_connection_string
    return if dependency_instance&.dependency.nil?

    dependency = dependency_instance.dependency
    password = dependency.configs["db_password"]
    username = dependency.configs["db_user"]
    db_name = dependency.configs["db_name"]

    "postgresql://#{username}:#{password}@postgresql/#{db_name}"
  end
end
