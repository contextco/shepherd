class AddTableSshPublicKeys < ActiveRecord::Migration[7.2]
  def change
    create_table :ssh_public_keys do |t|
      t.references :user, null: false, foreign_key: true
      t.string :key, null: false

      t.timestamps
    end
  end
end
