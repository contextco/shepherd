class AddColVpcNameServices < ActiveRecord::Migration[8.0]
  def change
    add_column :project_services, :pvc_name, :string
  end
end
