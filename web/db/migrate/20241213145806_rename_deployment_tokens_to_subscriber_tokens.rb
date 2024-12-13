class RenameDeploymentTokensToSubscriberTokens < ActiveRecord::Migration[8.0]
  def change
    rename_table :deployment_tokens, :project_subscriber_tokens
  end
end
