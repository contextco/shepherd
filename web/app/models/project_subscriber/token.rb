class ProjectSubscriber::Token < ApplicationRecord
  belongs_to :project_subscriber

  has_secure_token
end
