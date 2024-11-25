class AddColPvcSizeBytesAndPvcMountPathServices < ActiveRecord::Migration[8.0]
  def change
    add_column :project_services, :pvc_size_bytes, :bigint
    add_column :project_services, :pvc_mount_path, :string
  end
end
