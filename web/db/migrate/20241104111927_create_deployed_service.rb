class CreateDeployedService < ActiveRecord::Migration[7.2]
  def change
    create_table :deployed_services, id: :uuid do |t|
      t.references :application_project_version, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :image
      t.jsonb :environment_variables, default: {}
      t.jsonb :secrets, default: []
      t.jsonb :resources, default: {}
      t.timestamps
    end
  end
end
