# frozen_string_literal: true

module HasCurrency
  extend ActiveSupport::Concern

  included do
    enum currency: { USD: 'USD', EUR: 'EUR' }

    validates :currency, inclusion: { in: currencies.keys }
  end
end
