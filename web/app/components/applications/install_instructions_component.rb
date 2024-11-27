# frozen_string_literal: true

class Applications::InstallInstructionsComponent < ApplicationComponent
  attribute :version
  attribute :subscriber

  def project
    subscriber.project
  end

  def version_object
    version || subscriber.most_recent_version
  end

  def helm_repo
    subscriber.helm_repo
  end
end
