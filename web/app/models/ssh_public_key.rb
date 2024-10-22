# frozen_string_literal: true

class SshPublicKey < ApplicationRecord
  belongs_to :user
end
