# frozen_string_literal: true

class Services::DiskSliderComponent < ApplicationComponent
  attribute :form

  OPTIONS = [
    1.gigabytes, 5.gigabytes, 10.gigabytes, 50.gigabytes, 100.gigabytes, 500.gigabytes, 1.terabyte, 5.terabytes
  ].freeze
end
