# frozen_string_literal: true

module AuthorizationHelpers

  def authorization_options_for(deployment)
    { active_call_options: { metadata: { authorization: "Bearer #{deployment.tokens.first.token}" } } }
  end
end
