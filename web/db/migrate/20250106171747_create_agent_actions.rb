class CreateAgentActions < ActiveRecord::Migration[8.0]
  def change
    create_table :agent_actions, id: :uuid do |t|
      t.references :project_subscriber, null: false, foreign_key: true, type: :uuid
      t.integer :status
      t.string :type
      t.jsonb :data, default: {}
      t.timestamp :completed_at, null: true
      t.timestamps
    end
  end
end
