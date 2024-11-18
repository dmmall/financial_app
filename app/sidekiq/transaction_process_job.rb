# frozen_string_literal: true

class TransactionProcessJob
  include Sidekiq::Job

  sidekiq_options retry: 3

  def perform(transaction_id)
    transaction = Transaction.find(transaction_id)
    set_queue(transaction)

    TransferService.call(transaction)
  rescue ActiveRecord::RecordNotFound
    # Transaction was deleted, nothing to do
  end

  private

  def set_queue(transaction)
    queue = transaction.immediate? ? 'high_priority' : 'default'
    self.class.sidekiq_options queue: queue
  end
end
