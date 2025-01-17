# frozen_string_literal: true

class UI::FormResourcesComponent < ApplicationComponent
  attribute :form
  attribute :disk_options
  attribute :memory_options
  attribute :cpu_options
  attribute :fields, default: %i[cpu memory disk]
  attribute :disabled, default: false
  attribute :disabled_fields, default: []

  def cpu_disabled?
    disabled || disabled_fields.include?(:cpu)
  end

  def memory_disabled?
    disabled || disabled_fields.include?(:memory)
  end

  def disk_disabled?
    disabled || disabled_fields.include?(:disk)
  end
end
