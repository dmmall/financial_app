# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transactions::ValidatorService do
  subject(:service) { described_class.new(transaction, sender_wallet, recipient_wallet) }

  let(:sender_wallet) { create(:wallet, balance: 1000, currency: 'USD') }
  let(:recipient_wallet) { create(:wallet, currency: 'USD') }
  let(:transaction) do
    create(:transaction,
           amount: 100,
           sender_wallet: sender_wallet,
           recipient_wallet: recipient_wallet)
  end

  describe '#call' do
    context 'when all validations pass' do
      it 'does not raise error' do
        expect { service.call }.not_to raise_error
      end
    end

    context 'with insufficient funds' do
      let(:transaction) do
        create(:transaction,
               amount: 2000,
               sender_wallet: sender_wallet,
               recipient_wallet: recipient_wallet)
      end

      it 'raises error' do
        expect { service.call }.to raise_error(described_class::InsufficientFundsError)
      end
    end

    context 'with different currencies' do
      let(:recipient_wallet) { create(:wallet, currency: 'EUR') }

      it 'raises error' do
        expect { service.call }.to raise_error(described_class::CurrencyMismatchError)
      end
    end
  end
end
