class DroptableProjectSubscribersAndRecreate < ActiveRecord::Migration[8.0]
  def up
    drop_table :project_subscribers
    create_table :project_subscribers, id: :uuid do |t|
      t.references :project, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false

      t.timestamps
    end
  end
end
