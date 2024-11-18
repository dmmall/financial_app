# frozen_string_literal: true

class TransactionForm < BaseForm
  TRANSACTION_TYPES = Transaction.transaction_types.keys.freeze

  # Attributes
  attributes :amount,
             :currency,
             :transaction_type,
             :recipient_wallet_id,
             :sender_wallet_id

  optional_attributes :execution_date

  attr_reader :transaction,
              :sender,
              :sender_wallet,
              :recipient_wallet

  # Validations
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_type, presence: true, inclusion: { in: TRANSACTION_TYPES }
  validates :execution_date, presence: true, if: :scheduled?
  validates :execution_date, future_date: true, if: :scheduled?

  validate :validate_wallets
  validate :validate_sufficient_funds
  validate :validate_same_currency

  # Callbacks
  after_initialize :set_defaults

  # Constructor
  def initialize(attributes = {})
    attributes = attributes.to_h.symbolize_keys

    @sender = attributes.delete(:sender)
    @sender_wallet = attributes.delete(:sender_wallet)
    @recipient_wallet = attributes.delete(:recipient_wallet)

    attributes = parse_attributes(attributes)

    super(attributes)

    @transaction = Transaction.new
  end

  private

  # Core Methods
  def persist!
    transaction.assign_attributes(
      amount: amount,
      currency: currency,
      transaction_type: transaction_type,
      execution_date: execution_date,
      sender: sender,
      sender_wallet: sender_wallet,
      recipient_wallet: recipient_wallet
    )

    transaction.save!
    transaction
  end

  def set_defaults
    self.currency ||= sender_wallet&.currency
    self.execution_date = Time.current if immediate? && !execution_date_passed?
  end

  # Validation Methods
  def validate_wallets
    errors.add(:sender_wallet, :blank) if sender_wallet.blank?
    errors.add(:recipient_wallet, :blank) if recipient_wallet.blank?
    errors.add(:sender_wallet, :invalid) unless sender_wallet&.active?
    errors.add(:recipient_wallet, :invalid) unless recipient_wallet&.active?
    errors.add(:base, :same_wallet) if same_wallet?
  end

  def validate_sufficient_funds
    return if amount.blank? || sender_wallet.blank?
    return if sender_wallet.balance >= amount

    errors.add(:amount, :insufficient_funds)
  end

  def validate_same_currency
    return if currency.blank? || sender_wallet.blank? || recipient_wallet.blank?
    return if [sender_wallet.currency, recipient_wallet.currency].all?(currency)

    errors.add(:base, :different_currencies)
  end

  def parse_attributes(attributes)
    attributes.merge(
      amount: Parsers::AmountParser.parse(attributes[:amount]),
      execution_date: Parsers::DateParser.parse(attributes[:execution_date])
    )
  end

  # Query Methods
  def same_wallet?
    sender_wallet && recipient_wallet && sender_wallet.id == recipient_wallet.id
  end

  def scheduled?
    transaction_type == 'scheduled'
  end

  def immediate?
    transaction_type == 'immediate'
  end
end
