class AddColPredeployCommandServices < ActiveRecord::Migration[8.0]
  def change
    add_column :project_services, :predeploy_command, :string
  end
end
