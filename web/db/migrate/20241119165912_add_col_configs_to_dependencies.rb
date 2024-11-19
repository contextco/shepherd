class AddColConfigsToDependencies < ActiveRecord::Migration[7.2]
  def change
    add_column :dependencies, :configs, :jsonb, default: {}, null: false
  end
end
