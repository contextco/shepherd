# frozen_string_literal: true

class Services::ImageCredentialsComponent < ApplicationComponent
  attribute :form

  def existing_credentials?
    form.object.image_username.present? || form.object.image_password.present?
  end
end
