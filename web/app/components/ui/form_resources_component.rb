# frozen_string_literal: true

class UI::FormResourcesComponent < ApplicationComponent
  attribute :form
  attribute :disk_options
  attribute :memory_options
  attribute :cpu_options
  attribute :fields, default: %i[cpu memory disk]
end
