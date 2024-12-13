class ChangeRefInProjectSubscribersTokensToSubscribers < ActiveRecord::Migration[8.0]
  def change
    remove_reference :project_subscriber_tokens, :deployment, index: true, foreign_key: true

    add_reference :project_subscriber_tokens, :project_subscribers, index: true, foreign_key: true, type: :uuid
  end
end
