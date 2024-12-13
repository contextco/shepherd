class RenameContainersToAgentInstances < ActiveRecord::Migration[8.0]
  def change
    rename_table :containers, :agent_instances
  end
end
