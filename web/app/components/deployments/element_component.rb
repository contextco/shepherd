# frozen_string_literal: true

class Deployments::ElementComponent < ApplicationComponent
  attribute :deployment
  attribute :health_status, default: true
end
