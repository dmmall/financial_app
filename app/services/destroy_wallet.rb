# frozen_string_literal: true

class DestroyWallet
  def self.call(wallet)
    ActiveRecord::Base.transaction(isolation: :serializable) do
      wallet.sender_transactions.each do |transaction|
        transaction.update(status: :canceled)
      end
      wallet.destroy
    end
  end
end
