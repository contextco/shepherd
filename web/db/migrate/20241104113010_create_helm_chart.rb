class CreateHelmChart < ActiveRecord::Migration[7.2]
  def change
    create_table :helm_charts, id: :uuid do |t|
      t.references :owner, polymorphic: true, null: false, type: :uuid
      t.timestamps
    end
  end
end
