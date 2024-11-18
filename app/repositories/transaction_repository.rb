# frozen_string_literal: true

class TransactionRepository
  def initialize(relation = Transaction.all)
    @relation = relation
  end

  def find_for_user(user)
    relation
      .includes(
        {
          sender_wallet: :user,
          recipient_wallet: :user
        },
        :sender
      )
      .where(
        'sender_wallet_id IN (:wallet_ids) OR recipient_wallet_id IN (:wallet_ids)',
        wallet_ids: user.wallets.select(:id)
      )
      .distinct
      .order(created_at: :desc)
  end

  private

  attr_reader :relation
end
