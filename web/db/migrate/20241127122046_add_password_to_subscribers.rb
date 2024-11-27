class AddPasswordToSubscribers < ActiveRecord::Migration[8.0]
  def change
    add_column :project_subscribers, :password, :string
  end
end
