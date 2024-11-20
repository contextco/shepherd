class RemoveResourceColsFromDependencies < ActiveRecord::Migration[8.0]
  def change
    remove_column :dependencies, :cpu_cores, :float
    remove_column :dependencies, :memory_bytes, :bigint
    remove_column :dependencies, :disk_bytes, :bigint
  end
end
