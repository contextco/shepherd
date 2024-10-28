class CreateHealthLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :health_logs, id: :uuid do |t|
      t.references :container, null: false, foreign_key: true, type: :uuid
      t.string :lifecycle_id, null: false
      t.timestamps
    end

    add_column :containers, :name, :string, null: false
    remove_column :containers, :team_id, :uuid
  end
end
