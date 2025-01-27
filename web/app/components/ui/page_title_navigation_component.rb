# frozen_string_literal: true

class UI::PageTitleNavigationComponent < ApplicationComponent
  attribute :back_path
  attribute :back_text

  renders_one :title
end
