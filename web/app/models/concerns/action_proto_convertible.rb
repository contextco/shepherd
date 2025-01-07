# frozen_string_literal: true

module ActionProtoConvertible
  extend ActiveSupport::Concern

  included do
    def convert_to_proto
      "#{self.class.name}ProtoConverter".constantize.new(self).convert_to_proto
    end
  end
end
