class AddColStatusContainer < ActiveRecord::Migration[7.2]
  def change
    add_column :containers, :status, :integer, default: 0
  end
end
