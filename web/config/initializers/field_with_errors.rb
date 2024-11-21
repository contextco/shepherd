
# this disables field_with_errors divs on form errors https://railsdesigner.com/disable-field-with-errors/
ActionView::Base.field_error_proc = proc do |html_tag, _instance|
  html_tag.html_safe
end
