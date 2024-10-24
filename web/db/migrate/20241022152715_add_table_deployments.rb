class AddTableDeployments < ActiveRecord::Migration[7.2]
  def change
    create_table :deployments, id: :uuid do |t|
      t.references :team, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
