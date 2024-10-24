class DropdownComponent < ApplicationComponent
  renders_one :dropdown
  renders_one :disabled_content

  attribute :align, default: :right
  attribute :disabled, default: false
  attribute :expand_up, default: false
  attribute :custom_classes, default: ""
  attribute :match_trigger_width, default: false
end
