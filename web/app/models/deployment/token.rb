class Deployment::Token < ApplicationRecord
  belongs_to :deployment

  has_secure_token
end
