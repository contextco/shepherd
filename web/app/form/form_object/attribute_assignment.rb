# frozen_string_literal: true

# This module automatically converts incoming params to an unsafe hash. Since form itself is not connected to the
# database, we do not need to apply strong params pattern.

module FormObject::AttributeAssignment
  def assign_attributes(params)
    params = params.to_unsafe_hash if params.respond_to? :to_unsafe_hash
    super
  end
end
