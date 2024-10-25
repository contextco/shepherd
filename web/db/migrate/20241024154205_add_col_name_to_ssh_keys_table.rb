class AddColNameToSshKeysTable < ActiveRecord::Migration[7.2]
  def change
    add_column :ssh_public_keys, :name, :string
  end
end
