class AddProjectVersionToSubscriber < ActiveRecord::Migration[8.0]
  def change
    add_reference :project_subscribers, :project_version, null: true, foreign_key: true, type: :uuid
    change_column_null :project_subscribers, :project_id, true
  end
end
