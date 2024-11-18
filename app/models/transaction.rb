# frozen_string_literal: true

class Transaction < ApplicationRecord
  include AASM
  include HasCurrency

  belongs_to :sender, class_name: 'User'
  belongs_to :sender_wallet, class_name: 'Wallet', foreign_key: 'sender_wallet_id'
  belongs_to :recipient_wallet, class_name: 'Wallet', foreign_key: 'recipient_wallet_id'

  enum status: { pending: 0, processing: 1, completed: 2, canceled: 3, failed: 4 }
  enum transaction_type: { immediate: 0, scheduled: 1 }

  scope :scheduled, -> { where(transaction_type: :scheduled) }
  scope :pending, -> { where(status: :pending) }
  scope :completed, -> { where(status: :completed) }
  scope :failed, -> { where(status: :failed) }
  scope :canceled, -> { where(status: :canceled) }
  scope :delayed, lambda {
    scheduled.pending.where('execution_date > ?', Time.current)
  }

  aasm column: :status, enum: true do
    state :pending, initial: true
    state :processing
    state :completed
    state :canceled
    state :failed

    event :process do
      transitions from: :pending, to: :processing
    end

    event :complete do
      transitions from: :processing, to: :completed
    end

    event :cancel do
      transitions from: %i[pending processing], to: :canceled
    end

    event :fail do
      transitions from: %i[pending processing], to: :failed
    end

    after_all_transitions :log_state_change
  end

  def can_be_canceled?
    scheduled? && pending?
  end

  private

  def log_state_change
    Rails.logger.info "Transaction #{id} changed from #{aasm.from_state} to #{aasm.to_state}"
  end
end
