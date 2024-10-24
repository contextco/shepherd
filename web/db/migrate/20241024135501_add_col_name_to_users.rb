class AddColNameToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :name, :string
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :profile_picture_url, :string
    add_reference :users, :team, foreign_key: true, type: :uuid
  end
end
