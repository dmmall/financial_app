# frozen_string_literal: true

class ScheduledTransactionsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default,
                  retry: 3,
                  lock: :until_executed,
                  lock_timeout: 1.hour

  def perform
    ready_transactions.find_each(batch_size: 100) do |transaction|
      process_transaction(transaction)
    end
  end

  private

  def ready_transactions
    Transaction
      .delayed
      .where('execution_date > ?', 1.day.ago)
      .order(execution_date: :asc)
  end

  def process_transaction(transaction)
    TransactionProcessJob.set(queue: :default).perform_later(transaction.id)
  rescue StandardError => e
    Rails.logger.error("Failed to schedule transaction #{transaction.id}: #{e.message}")
    Sentry.capture_exception(e, extra: { transaction_id: transaction.id }) if defined?(Sentry)
  end
end
