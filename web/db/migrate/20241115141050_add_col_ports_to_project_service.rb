class AddColPortsToProjectService < ActiveRecord::Migration[7.2]
  def change
    add_column :project_services, :ports, :jsonb, default: []
  end
end
