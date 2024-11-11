class CreateHelmUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :helm_users, id: :uuid do |t|
      t.references :project, type: :uuid, null: false, foreign_key: true
      t.string :name
      t.string :password
      t.timestamps
    end
  end
end
