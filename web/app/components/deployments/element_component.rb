# frozen_string_literal: true

class Deployments::ElementComponent < ApplicationComponent
  attribute :name
  attribute :health_status, default: true
end
