class CreateDeploymentTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :deployment_tokens, id: :uuid do |t|
      t.references :deployment, null: false, foreign_key: true, type: :uuid

      t.string :token, null: false

      t.timestamps
    end
  end
end
