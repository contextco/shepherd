class AddImageUsernameandImagePasswordToProjectService < ActiveRecord::Migration[8.0]
  def change
    add_column :project_services, :image_username, :string
    add_column :project_services, :image_password, :string
  end
end
