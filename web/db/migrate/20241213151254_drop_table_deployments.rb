class DropTableDeployments < ActiveRecord::Migration[8.0]
  def change
    drop_table :deployments
  end
end
