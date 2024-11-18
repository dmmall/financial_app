# frozen_string_literal: true

class WalletRepository
  def initialize(relation = Wallet.all)
    @relation = relation
  end

  def available_for_user(user, currency: nil)
    scope = relation
            .includes(:user)
            .where.not(user_id: user.id)
            .active

    scope = scope.where(currency: currency) if currency.present?
    scope
  end

  private

  attr_reader :relation
end
