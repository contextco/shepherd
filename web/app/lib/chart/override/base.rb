# frozen_string_literal: true

class Chart::Override::Base
  class InvalidConfigError < StandardError; end

  private

  def convert_value(name, value, value_types)
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
