class UpdateHelUsers < ActiveRecord::Migration[7.2]
  def change
    remove_column :helm_users, :project_id, :uuid

    add_reference :helm_users, :helm_repo, null: false, foreign_key: true, type: :uuid
  end
end
