class CreateApplicationProject < ActiveRecord::Migration[7.2]
  def change
    create_table :application_projects, id: :uuid do |t|
      t.string :name
      t.references :team, null: false, foreign_key: true, type: :uuid
      t.timestamps
    end
  end
end
