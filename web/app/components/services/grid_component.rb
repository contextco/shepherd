# frozen_string_literal: true

class Services::GridComponent < ApplicationComponent
  attribute :project_version

  def services
    project_version&.project_services || []
  end
end
