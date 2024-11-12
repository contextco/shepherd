class AddCPUAndMemoryToService < ActiveRecord::Migration[7.2]
  def change
    add_column :project_services, :cpu_cores, :float
    add_column :project_services, :memory_bytes, :bigint

    remove_column :project_services, :resources, :jsonb
  end
end
