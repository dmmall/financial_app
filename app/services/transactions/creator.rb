# frozen_string_literal: true

module Transactions
  class Creator
    def self.call(transaction_params)
      transaction = TransactionForm.new(transaction_params)
      if transaction.save
        Executor.call(transaction.result)
      else
        transaction
      end
    end
  end
end
