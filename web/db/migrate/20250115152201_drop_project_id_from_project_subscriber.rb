class DropProjectIdFromProjectSubscriber < ActiveRecord::Migration[8.0]
  def change
    remove_column :project_subscribers, :project_id

    remove_column :project_versions, :agent
  end
end
