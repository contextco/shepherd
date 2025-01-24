# frozen_string_literal: true

class Services::ImageValidationComponent < ApplicationComponent
  attribute :validation_result

  COMPONENT_ID = "image-validation-component".freeze

  def image_valid?
    validation_result.present? && validation_result.valid
  end

  def image_invalid?
    validation_result.present? && !validation_result.valid
  end

  def image_validation_message
    validation_result&.error_message || "Image is valid and accessible."
  end
end
