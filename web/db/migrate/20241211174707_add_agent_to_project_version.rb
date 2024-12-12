class AddAgentToProjectVersion < ActiveRecord::Migration[8.0]
  def change
    add_column :project_versions, :agent, :integer, default: 0
  end
end
