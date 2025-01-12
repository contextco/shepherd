class AddActionedByToPlans < ActiveRecord::Migration[8.0]
  def change
    add_reference :agent_actions, :created_by, foreign_key: { to_table: :users }, type: :uuid
  end
end
