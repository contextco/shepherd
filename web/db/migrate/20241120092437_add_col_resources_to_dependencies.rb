class AddColResourcesToDependencies < ActiveRecord::Migration[8.0]
  def change
    add_column :dependencies, :cpu_cores, :float
    add_column :dependencies, :memory_bytes, :bigint
  end
end
