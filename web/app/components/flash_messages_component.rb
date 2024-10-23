# frozen_string_literal: true

# TODO: Would be really nice to support multiple messages like Linear does...
class FlashMessagesComponent < ViewComponent::Base
  def initialize(flash:)
    @flash = flash
  end

  def message
    @flash[:notice] || @flash[:error]
  end

  def progress_bar_color
    case @flash.keys.first.to_sym
    when :error
      "bg-red-600"
    else
      "bg-stone-100"
    end
  end
end
