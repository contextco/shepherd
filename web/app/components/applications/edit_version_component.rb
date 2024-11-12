# frozen_string_literal: true

class Applications::EditVersionComponent < ApplicationComponent
  attribute :version

  def enabled?
    version.draft?
  end
end
