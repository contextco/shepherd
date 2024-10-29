class DropHealthLogs < ActiveRecord::Migration[7.2]
  def up
    drop_table :health_logs
  end

  def down
    create_table :health_logs, id: :uuid do |t|
      t.references :container, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end
  end
end
