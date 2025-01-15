class AddAgentToProjectSubscriber < ActiveRecord::Migration[8.0]
  def change
    add_column :project_subscribers, :agent, :integer, default: 0
  end
end
