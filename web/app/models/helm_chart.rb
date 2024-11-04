# frozen_string_literal: true

class HelmChart < ApplicationRecord
  belongs_to :owner, polymorphic: true
end
