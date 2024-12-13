class ChangeRefInAgentInstancesToSubscribers < ActiveRecord::Migration[8.0]
  def change
    remove_reference :agent_instances, :deployment, index: true, foreign_key: true
    add_reference :agent_instances, :project_subscriber, index: true, foreign_key: true, type: :uuid
  end
end
