# frozen_string_literal: true

class Applications::PreviewChartComponent < ApplicationComponent
  attribute :version

  def disabled?
    !version.deployable?
  end
end
