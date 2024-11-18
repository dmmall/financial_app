# frozen_string_literal: true

module Transactions
  class Canceler
    attr_reader :transaction, :errors

    def initialize(transaction)
      @transaction = transaction
      @errors = ActiveModel::Errors.new(self)
    end

    def call
      return add_error('Cannot cancel this transaction') unless transaction.can_be_canceled?

      transaction.update(status: :canceled)
    end

    private

    def add_error(message)
      errors.add(:base, message)
      false
    end
  end
end
