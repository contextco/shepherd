class AddColDiskToDependencies < ActiveRecord::Migration[8.0]
  def change
    add_column :dependencies, :disk_bytes, :bigint
  end
end
