# frozen_string_literal: true

module Comparisons::Service
  def self.compare(base, incoming)
    simple_compares = {
      image: "Image",
      cpu_cores: "CPU Cores",
      memory_bytes: "Memory",
      predeploy_command: "Predeploy Command",
      ingress_port: "Ingress Port",
      image_username: "Image Username",
      image_password: "Image Password"
    }
    changes = Comparisons::Common.simple_comparisons(simple_compares, base:, incoming:)

    env_var_changes = Comparisons::Common.array_hash_comparisons(
      key_field: "name",
      value_field: "value",
      base: base.environment_variables,
      incoming: incoming.environment_variables,
      display_field: "Environment Variable"
    )

    secrets_changes = Comparisons::Common.array_comparisons(
      base: base.secrets.map(&:environment_key),
      incoming: incoming.secrets.map(&:environment_key),
      display_field: "Secret"
    )

    ports_changes = Comparisons::Common.array_comparisons(
      base: base.ports,
      incoming: incoming.ports,
      display_field: "Port"
    )

    changes + env_var_changes + secrets_changes + ports_changes
  end
end
