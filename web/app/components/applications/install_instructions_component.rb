# frozen_string_literal: true

class Applications::InstallInstructionsComponent < ApplicationComponent
  attribute :version
  attribute :subscriber

  attribute :internal, default: true # different endpoint required for values.yaml download (auth reasons)

  def project
    subscriber.project
  end

  def version_object
    version || subscriber.most_recent_version
  end

  def helm_repo
    subscriber.helm_repo
  end

  def values_url
    # both these endpoints have auth, docs page has a password check (no account), subscriber page has a session token (account)
    return client_values_yaml_project_subscriber_path(subscriber, project_version_id: version_object.id, format: :yaml) if internal

    client_values_yaml_doc_path(subscriber, project_version_id: version_object.id, format: :yaml)
  end
end
