# frozen_string_literal: true

class TransactionDecorator < Draper::Decorator
  delegate_all

  def self.transaction_type_options
    Transaction.transaction_types.keys.map { |type| [type.humanize, type] }
  end
end
