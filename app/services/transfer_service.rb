# frozen_string_literal: true

class TransferService
  Error = Transactions::ValidatorService::Error

  MAX_RETRIES = 3
  RETRY_DELAY = 0.1

  def self.call(...)
    new(...).call
  end

  def initialize(money_transaction, logger: Rails.logger)
    @money_transaction = money_transaction
    @logger = logger
    @attempts = 0
  end

  def call
    with_logging do
      with_retries do
        perform_transfer
      end
    end
  rescue Error => e
    handle_service_error(e)
  rescue StandardError => e
    handle_unexpected_error(e)
  end

  private

  attr_reader :money_transaction, :logger, :attempts

  def perform_transfer
    ActiveRecord::Base.transaction do
      sender_wallet, recipient_wallet = lock_wallets_for_update

      Transactions::ValidatorService.call(money_transaction, sender_wallet, recipient_wallet)
      execute_transfer(sender_wallet, recipient_wallet)
      complete_transfer
    end
  end

  def lock_wallets_for_update
    wallet_ids = [
      money_transaction.sender_wallet_id,
      money_transaction.recipient_wallet_id
    ].sort

    wallets = Wallet.where(id: wallet_ids)
                    .order(:id)
                    .lock('FOR UPDATE')
                    .to_a

    if wallet_ids.first == money_transaction.sender_wallet_id
      wallets
    else
      wallets.reverse
    end
  end

  def execute_transfer(sender_wallet, recipient_wallet)
    logger.info(
      "Executing transfer: #{money_transaction.id}, " \
      "amount: #{money_transaction.amount}, " \
      "from: #{sender_wallet.id}, " \
      "to: #{recipient_wallet.id}"
    )

    sender_wallet.update!(
      balance: sender_wallet.balance - money_transaction.amount
    )

    recipient_wallet.update!(
      balance: recipient_wallet.balance + money_transaction.amount
    )
  end

  def complete_transfer
    money_transaction.update!(
      status: :completed,
      completed_at: Time.current
    )
  end

  def with_retries
    yield
  rescue ActiveRecord::StatementInvalid => e
    @attempts += 1

    raise Error, "Max retries reached: #{e.message}" unless attempts < MAX_RETRIES

    sleep(RETRY_DELAY * attempts)
    logger.warn("Retrying transfer #{money_transaction.id}, attempt #{attempts}")
    retry
  end

  def with_logging
    logger.info("Starting transfer #{money_transaction.id}")
    start_time = Time.current
    result = yield
    duration = Time.current - start_time
    logger.info("Completed transfer #{money_transaction.id} in #{duration.round(2)}s")
    result
  end

  def handle_service_error(error)
    log_error(error)
    fail_transaction(error.message)
    raise error
  end

  def handle_unexpected_error(error)
    log_error(error)
    fail_transaction("Unexpected error: #{error.message}")
    raise error
  end

  def fail_transaction(_message)
    money_transaction.update!(
      status: :failed,
      completed_at: Time.current
    )
  end

  def log_error(error)
    logger.error(
      "Transfer failed: #{money_transaction.id}, " \
      "error: #{error.class} - #{error.message}"
    )
  end
end
