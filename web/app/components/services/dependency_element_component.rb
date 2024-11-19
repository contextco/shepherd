# frozen_string_literal: true

class Services::DependencyElementComponent < ApplicationComponent
  attribute :dependency
  attribute :version

  def enabled?
    version.draft?
  end
end
