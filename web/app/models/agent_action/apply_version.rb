class AgentAction::ApplyVersion < AgentAction
  include ActionProtoConvertible

  store_accessor :data, :source_version_id, :target_version_id

  delegate :helm_repo, to: :subscriber

  def source_version
    ProjectVersion.find(source_version_id)
  end

  def target_version
    ProjectVersion.find(target_version_id)
  end
end
