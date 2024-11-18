# frozen_string_literal: true

class Wallet < ApplicationRecord
  include HasCurrency

  belongs_to :user
  has_many :sender_transactions, class_name: 'Transaction', foreign_key: 'sender_wallet_id'
  has_many :recipient_transactions, class_name: 'Transaction', foreign_key: 'recipient_wallet_id'

  scope :active, -> { where(active: true) }

  validates :balance, numericality: { greater_than_or_equal_to: 0 }

  before_destroy :ensure_no_active_transactions

  private

  def ensure_no_active_transactions
    return unless transactions.where.not(status: :canceled).exists?

    errors.add(:base, 'Cannot delete wallet with active transactions')
    throw :abort
  end
end
