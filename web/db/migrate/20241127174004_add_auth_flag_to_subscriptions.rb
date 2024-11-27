class AddAuthFlagToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :project_subscribers, :auth, :boolean, default: true, null: false
  end
end
