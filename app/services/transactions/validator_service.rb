# frozen_string_literal: true

module Transactions
  class ValidatorService
    class Error < StandardError; end
    class InsufficientFundsError < Error; end
    class WalletNotFoundError < Error; end
    class InvalidTransactionError < Error; end
    class CurrencyMismatchError < Error; end

    def self.call(...)
      new(...).call
    end

    def initialize(money_transaction, sender_wallet, recipient_wallet)
      @money_transaction = money_transaction
      @sender_wallet = sender_wallet
      @recipient_wallet = recipient_wallet
    end

    def call
      validate_wallets_presence!
      validate_wallets_active!
      validate_transaction_state!
      validate_currencies!
      validate_sufficient_funds!
      validate_wallets_different!
    end

    private

    attr_reader :money_transaction, :sender_wallet, :recipient_wallet

    def validate_wallets_presence!
      raise WalletNotFoundError, 'Sender wallet not found' unless sender_wallet
      raise WalletNotFoundError, 'Recipient wallet not found' unless recipient_wallet
    end

    def validate_wallets_active!
      raise InvalidTransactionError, 'Sender wallet inactive' unless sender_wallet.active?
      raise InvalidTransactionError, 'Recipient wallet inactive' unless recipient_wallet.active?
    end

    def validate_transaction_state!
      raise InvalidTransactionError, 'Transaction already processed' if money_transaction.processing?
      raise InvalidTransactionError, 'Transaction cancelled' if money_transaction.canceled?
    end

    def validate_currencies!
      return if sender_wallet.currency == recipient_wallet.currency

      raise CurrencyMismatchError,
            "Currency mismatch: #{sender_wallet.currency} -> #{recipient_wallet.currency}"
    end

    def validate_sufficient_funds!
      return if sender_wallet.balance >= money_transaction.amount

      raise InsufficientFundsError,
            "Insufficient funds: available #{sender_wallet.balance}, needed #{money_transaction.amount}"
    end

    def validate_wallets_different!
      return unless sender_wallet.id == recipient_wallet.id

      raise InvalidTransactionError, 'Cannot transfer to the same wallet'
    end
  end
end
