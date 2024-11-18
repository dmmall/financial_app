# frozen_string_literal: true

class WalletDecorator < Draper::Decorator
  delegate_all

  def display_name
    "#{object.user.email} (#{object.currency})"
  end
end
