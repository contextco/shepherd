class CreateTableEventLog < ActiveRecord::Migration[7.2]
  def change
    create_table :event_logs, id: :uuid do |t|
      t.references :container, type: :uuid, null: false, foreign_key: true
      t.integer :event_type, default: 0, null: false
      t.jsonb :payload, null: false, default: {}
      t.timestamps
    end
  end
end
