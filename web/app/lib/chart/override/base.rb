# frozen_string_literal: true

class Chart::Override::Base
  class InvalidConfigError < StandardError; end

  private

# Converts the given value to a Google::Protobuf::Value based on the specified value type.
#
# @param name [String, Symbol] the name of the config parameter
# @param value [Object] the value to be converted
# @param value_types [Hash] a hash mapping config parameter names to their value types (:number or :string)
# @yield [Object] an optional block to transform the value before conversion
# @return [Google::Protobuf::Value] the converted Google::Protobuf::Value
# @raise [InvalidConfigError] if the value type is unknown
def convert_value(name, value, value_types)
  value = yield(value) if block_given?

  case value_types[name.to_sym]
  when :number
    Google::Protobuf::Value.new(number_value: value)
  when :string
    Google::Protobuf::Value.new(string_value: value)
  else
    raise InvalidConfigError, "Unknown value type for config: #{name}"
  end
end
end
