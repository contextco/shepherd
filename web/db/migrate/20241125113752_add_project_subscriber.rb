class AddProjectSubscriber < ActiveRecord::Migration[8.0]
  def change
    create_table :project_subscribers do |t|
      t.references :project, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false

      t.timestamps
    end
  end
end
