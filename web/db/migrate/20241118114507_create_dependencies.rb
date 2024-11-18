class CreateDependencies < ActiveRecord::Migration[7.2]
  def change
    create_table :dependencies, id: :uuid do |t|
      t.string :name, null: false
      t.string :version, null: false
      t.string :repo_url, null: false

      t.references :project_version, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
