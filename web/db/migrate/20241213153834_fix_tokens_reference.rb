class FixTokensReference < ActiveRecord::Migration[8.0]
  def change
    rename_column :project_subscriber_tokens, :project_subscribers_id, :project_subscriber_id
  end
end
