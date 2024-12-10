# frozen_string_literal: true

class Chart::Override::Base
  class InvalidConfigError < StandardError; end

  private

def convert_value(name, value, value_type)
  value = yield(value) if block_given?

  case value_type
  when :number
    Google::Protobuf::Value.new(number_value: value)
  when :string
    Google::Protobuf::Value.new(string_value: value)
  when :list
    Google::Protobuf::Value.new(list_value: value)
  else
    raise InvalidConfigError, "Unknown value type for config: #{name}"
  end
end
end
