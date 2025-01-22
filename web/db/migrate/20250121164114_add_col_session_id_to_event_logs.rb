class AddColSessionIdToEventLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :event_logs, :session_id, :string, default: nil

    add_index :event_logs, :session_id
  end
end
