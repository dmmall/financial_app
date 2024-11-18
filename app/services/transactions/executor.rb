# frozen_string_literal: true

module Transactions
  class Executor
    def self.call(...)
      new(...).call
    end

    def initialize(transaction)
      @transaction = transaction
    end

    def call
      schedule_execution
      transaction
    end

    private

    attr_reader :transaction

    def schedule_execution
      delayed_execution? ? schedule_delayed_execution : schedule_immediate_execution
    end

    def schedule_immediate_execution
      ::TransactionProcessJob.perform_async(transaction.id)
    end

    def schedule_delayed_execution
      ::TransactionProcessJob.perform_at(
        transaction.execution_date,
        transaction.id
      )
    end

    def delayed_execution?
      transaction.scheduled? && transaction.execution_date.future?
    end
  end
end
