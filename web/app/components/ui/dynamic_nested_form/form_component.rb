# frozen_string_literal: true

class UI::DynamicNestedForm::FormComponent < ApplicationComponent
  attribute :model_class
  attribute :association_name
  attribute :form
  attribute :wrapper_classes
  attribute :id
  attribute :maximum_subforms, default: 10
  attribute :minimum_subforms, default: 1
  attribute :always_renders_one, default: true

  renders_one :subform_content, lambda { |&block|
    @block = block
    subform(&block)
  }

  def association_name
    super || model_class.model_name.plural
  end

  def subform(model = model_class.new, index: nil, &block)
    index ||= index_placeholder_string
    form.fields_for(association_name.to_sym, model, child_index: index, &block || @block)
  end

  def index_placeholder_string
    @index_placeholder_string ||= "id-#{SecureRandom.hex(5)}"
  end

  def previous_values
    form.object.send(association_name)
  end

  def initial_subforms_count_value
    [ previous_values.size, minimum_subforms ].max
  end
end
