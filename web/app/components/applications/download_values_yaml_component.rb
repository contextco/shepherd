# frozen_string_literal: true

class Applications::DownloadValuesYamlComponent < ApplicationComponent
  attribute :version

  def render?
    version.published?
  end
end
