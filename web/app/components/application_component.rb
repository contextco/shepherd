# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  include ActiveModel::Attributes
  include ActiveModel::AttributeAssignment
  include RailsHeroicon::Helper

  delegate :current_user, :current_team, :user_signed_in?, to: :helpers

  def initialize(**args)
    super
    assign_attributes(args)
  end
end
