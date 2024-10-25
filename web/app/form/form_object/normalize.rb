# frozen_string_literal: true

module FormObject::Normalize
  extend ActiveSupport::Concern

  class_methods do
    def normalize(attribute, with: nil)
      define_method("#{attribute}=") do |value|
        normalizer = with || ->(v) { v }
        normalizer = method(with) if with.is_a?(Symbol)
        normalizer = ->(v) { with.reduce(v) { |memo, symbol| method(symbol).call(memo) } } if with.is_a?(Array)

        super(normalizer.call(value))
      end
    end
  end
end
