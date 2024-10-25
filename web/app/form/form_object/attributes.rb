# frozen_string_literal: true

module FormObject::Attributes
  def [](attribute)
    klass = self.class
    return unless klass.attribute_names.include?(attribute.to_s) || klass.nested_attributes.key?(attribute.to_sym)

    public_send(attribute)
  end

  def attributes(symbolize: false)
    result = super()
    result = result.symbolize_keys if symbolize
    result
  end
end
