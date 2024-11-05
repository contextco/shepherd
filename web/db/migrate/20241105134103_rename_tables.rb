class RenameTables < ActiveRecord::Migration[7.2]
  def change
    rename_table :application_projects, :projects
    rename_table :application_project_versions, :project_versions
    rename_table :deployed_services, :project_services

    remove_reference :project_versions, :application_project, index: true
    add_reference :project_versions, :project, index: true, foreign_key: true, type: :uuid

    remove_reference :project_services, :application_project_version, index: true
    add_reference :project_services, :project_version, index: true, foreign_key: true, type: :uuid
  end
end
