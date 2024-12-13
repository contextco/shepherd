# frozen_string_literal: true

module AuthorizationHelpers
  def authorization_options_for(project_subscriber)
    { active_call_options: { metadata: { "authorization" => "Bearer #{project_subscriber.tokens.first.token}" } } }
  end
end
