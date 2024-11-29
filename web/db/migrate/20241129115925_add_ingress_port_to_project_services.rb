class AddIngressPortToProjectServices < ActiveRecord::Migration[8.0]
  def change
    add_column :project_services, :ingress_port, :integer
  end
end
