# frozen_string_literal: true

class Applications::PublishButtonComponent < ApplicationComponent
  attribute :version

  def render?
    # remove this when we support unpublishing
    !version.published?
  end
end
