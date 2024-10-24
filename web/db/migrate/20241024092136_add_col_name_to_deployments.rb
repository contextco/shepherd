class AddColNameToDeployments < ActiveRecord::Migration[7.2]
  def change
    add_column :deployments, :name, :string, null: false
  end
end
