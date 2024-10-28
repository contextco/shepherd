# frozen_string_literal: true

class SSHPublicKey < ApplicationRecord
  belongs_to :user
end
