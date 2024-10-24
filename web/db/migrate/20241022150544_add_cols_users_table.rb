class AddColsUsersTable < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :name, :string
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :profile_picture_url, :string
  end
end
