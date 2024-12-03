class AddChartNameToDependencies < ActiveRecord::Migration[8.0]
  def change
    add_column :dependencies, :chart_name, :string
  end
end
