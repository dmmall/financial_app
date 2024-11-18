# frozen_string_literal: true

class User < ApplicationRecord
  has_many :wallets

  validates :email, presence: true

  def wallet(currency)
    wallets.find_by(currency: currency)
  end
end
