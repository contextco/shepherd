class AgentAction::ApplyVersion < AgentAction
  include ActionProtoConvertible

  store_accessor :data, :project_version_id

  delegate :helm_repo, to: :subscriber

  def project_version
    ProjectVersion.find(project_version_id)
  end
end
