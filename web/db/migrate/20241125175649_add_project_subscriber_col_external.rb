class AddProjectSubscriberColExternal < ActiveRecord::Migration[8.0]
  def change
    add_column :project_subscribers, :dummy, :boolean, default: false, null: false
  end
end
