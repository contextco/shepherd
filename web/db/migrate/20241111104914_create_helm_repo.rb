class CreateHelmRepo < ActiveRecord::Migration[7.2]
  def change
    create_table :helm_repos, id: :uuid do |t|
      t.references :project, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.timestamps

      t.index %i[project_id name], unique: true
    end
  end
end
