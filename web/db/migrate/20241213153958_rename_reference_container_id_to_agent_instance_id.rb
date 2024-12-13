class RenameReferenceContainerIdToAgentInstanceId < ActiveRecord::Migration[8.0]
  def change
    rename_column :event_logs, :container_id, :agent_instance_id
  end
end
