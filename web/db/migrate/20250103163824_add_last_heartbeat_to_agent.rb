class AddLastHeartbeatToAgent < ActiveRecord::Migration[8.0]
  def change
    remove_column :agent_instances, :status, :integer, default: 0
    add_column :agent_instances, :last_heartbeat_at, :datetime
  end
end
