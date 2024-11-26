class RemoveProjectIdFromHelmRepo < ActiveRecord::Migration[8.0]
  def change
    remove_column :helm_repos, :project_id, :bigint
    change_column_null :helm_repos, :project_subscriber_id, false
  end
end
