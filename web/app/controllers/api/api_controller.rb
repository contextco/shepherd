# frozen_string_literal: true

module Api
  class ApiController < ActionController::API
    include Concerns::Authentication
    include Concerns::UseForm

    wrap_parameters false
  end
end
