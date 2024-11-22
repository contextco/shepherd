# frozen_string_literal: true

class Services::FormDiskComponent < ApplicationComponent
  attribute :form

  DEFAULT_OPTIONS = [
    1.gigabytes, 5.gigabytes, 10.gigabytes, 50.gigabytes, 100.gigabytes, 500.gigabytes
  ].freeze

  attribute :options, default: DEFAULT_OPTIONS

  def options_value
    options || DEFAULT_OPTIONS
  end

  def existing_mount?
    form.object.pvc_mount_path.present?
  end
end
