# frozen_string_literal: true

class Services::ElementComponent < ApplicationComponent
  attribute :service
  attribute :version

  def enabled?
    version.draft?
  end
end
