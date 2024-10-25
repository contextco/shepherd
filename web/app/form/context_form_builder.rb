# frozen_string_literal: true

class ContextFormBuilder < ActionView::Helpers::FormBuilder
  def label(method, text = nil, options = {}, &)
    options[:class] = "#{options[:class]} form-label"
    super
  end

  def text_field(method, options = {})
    options[:class] = "#{options[:class]} outline-none border-slate-200 shadow"
    super
  end

  def text_area(method, options = {})
    options[:class] = "#{options[:class]} outline-none border-slate-200 shadow rounded"
    super
  end

  def submit(value = "", options = {})
    options[:class] = "#{options[:class]}"
    super
  end
end
