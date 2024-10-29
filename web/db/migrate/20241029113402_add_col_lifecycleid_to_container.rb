class AddColLifecycleidToContainer < ActiveRecord::Migration[7.2]
  def up
    add_column :containers, :lifecycle_id, :string, null: false
    remove_column :health_logs, :lifecycle_id
  end

  def down
    remove_column :containers, :lifecycle_id
    add_column :health_logs, :lifecycle_id, :string, null: false
  end
end
