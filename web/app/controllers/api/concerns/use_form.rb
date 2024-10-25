# frozen_string_literal: true

module Api::Concerns::UseForm
  extend ActiveSupport::Concern

  included do
    before_action :validate_form
  end

  private

  def validate_form
    return if form.valid?

    render json: { error: form.errors.to_hash }, status: :bad_request
  end

  def form
    return @form if defined? @form

    matching_definitions = self.class.forms.select { |definition| definition.matches?(action_name) }
    raise "Multiple matching forms found for `#{self.class.name}##{action_name}`" if matching_definitions.count > 1

    definition = matching_definitions.first
    extra_keys = definition&.extra_keys || :error
    form_class = definition&.form_class || Api::BlankForm
    @form = form_class.new(form_params, extra_keys:)
    prepare_form(@form)
    @form
  end

  def prepare_form(_form); end

  # Rails `params` contains path_params, which should not be passed to the form
  def form_params
    request.query_parameters.merge(request.request_parameters)
  end

  Definition = Struct.new(:form_class, :only, :except, :extra_keys) do
    def initialize(*)
      super
      self.only = only && Array.wrap(only).map(&:to_sym)
      self.except = Array.wrap(except).map(&:to_sym)
      self.extra_keys = extra_keys&.to_sym
    end

    def matches?(action_name)
      return false if only&.exclude?(action_name.to_sym)
      return false if except.include?(action_name.to_sym)

      true
    end
  end

  module ClassMethods
    def use_form(form_class, only: nil, except: nil, extra_keys: nil)
      forms << Definition.new(form_class, only, except, extra_keys)
    end

    def forms
      @forms ||= []
    end
  end
end
