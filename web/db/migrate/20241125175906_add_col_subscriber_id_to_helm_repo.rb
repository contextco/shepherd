class AddColSubscriberIdToHelmRepo < ActiveRecord::Migration[8.0]
  def change
    add_reference :helm_repos, :project_subscriber, foreign_key: true, type: :uuid
    #   make project_id nullable
    change_column_null :helm_repos, :project_id, true
  end
end
