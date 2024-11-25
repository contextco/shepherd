class ChangeProjectSubscribersIdToUudi < ActiveRecord::Migration[8.0]
  def up
    remove_column :project_subscribers, :id
    add_column :project_subscribers, :id, :uuid, default: "gen_random_uuid()", primary_key: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
