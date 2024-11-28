# frozen_string_literal: true

class Sidebar::IconComponent < ApplicationComponent
  attribute :icon
  attribute :path
  attribute :label

  attribute :associated_controllers, default: []
end
