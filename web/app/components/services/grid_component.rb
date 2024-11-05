# frozen_string_literal: true

class Services::GridComponent < ApplicationComponent
  attribute :application_version

  def services
    application_version&.deployed_services || []
  end
end
