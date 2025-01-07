# frozen_string_literal: true

require "service_pb"
class AgentAction::ApplyVersionProtoConverter
  def initialize(apply_version_action)
    @action = apply_version_action
  end

  def convert_to_proto
    ApplyResponse.new(
      action: Action.new(
        id: @action.id,
        apply_chart: ApplyChartRequest.new(
          chart: helm_repo.chart_file(project_version).download,
        ),
      )
    )
  end

  private

  delegate :helm_repo, :project_version, to: :@action
end
