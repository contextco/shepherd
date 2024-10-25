# frozen_string_literal: true

# ArbitraryAttributes is a form object that allows any attributes to be passed in.
# It's useful when you want to define an attribute that can have any key-value pairs, but still want to perform some basic sanity checking on this payload (eg: cardinality of keys, maximum depth of nesting, etc).
class FormObject::ArbitraryAttributes
  include FormObject

  def initialize(params = {}, **options)
    @options = options.merge(extra_keys: :ignore)
    super(params)
  end

  attribute :payload

  def assign_attributes(payload)
    self.payload = payload
  end

  def attributes
    payload
  end

  # TODO: Add validations for cardinality of keys
  # TODO: Add validations for maximum depth of nesting
end
