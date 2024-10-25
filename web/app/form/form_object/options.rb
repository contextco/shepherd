# frozen_string_literal: true

module FormObject::Options
  def initialize(params = {}, **options)
    @options = options
    super(params)
  end
end
