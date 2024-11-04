class CreateApplicationProjectVersion < ActiveRecord::Migration[7.2]
  def change
    create_table :application_project_versions, id: :uuid do |t|
      t.references :application_project, null: false, foreign_key: true, type: :uuid
      t.integer :state, null: false, default: 0

      t.string :version, null: false # semantic versioning of the helm chart
      t.string :description


      t.timestamps
    end
  end
end
