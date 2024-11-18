# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TransactionForm do
  let(:sender) { create(:user) }
  let(:sender_wallet) { create(:wallet, user: sender, balance: 1000) }
  let(:recipient_wallet) { create(:wallet) }

  let(:valid_attributes) do
    {
      amount: 100,
      currency: 'USD',
      transaction_type: 'immediate',
      sender: sender,
      sender_wallet: sender_wallet,
      recipient_wallet: recipient_wallet
    }
  end

  describe 'validations' do
    context 'amount validations' do
      it 'requires amount to be present' do
        form = described_class.new(valid_attributes.merge(amount: nil))
        expect(form).not_to be_valid
        expect(form.errors[:amount]).to include("can't be blank")
      end

      it 'requires amount to be greater than 0' do
        form = described_class.new(valid_attributes.merge(amount: 0))
        expect(form).not_to be_valid
        expect(form.errors[:amount]).to include('must be greater than 0')
      end
    end

    context 'transaction_type validations' do
      it 'requires transaction_type to be present' do
        form = described_class.new(valid_attributes.merge(transaction_type: nil))
        expect(form).not_to be_valid
        expect(form.errors[:transaction_type]).to include("can't be blank")
      end

      it 'requires transaction_type to be valid' do
        form = described_class.new(valid_attributes.merge(transaction_type: 'invalid'))
        expect(form).not_to be_valid
        expect(form.errors[:transaction_type]).to include('is not included in the list')
      end
    end

    context 'when scheduled' do
      it 'requires execution_date to be present' do
        form = described_class.new(valid_attributes.merge(
                                     transaction_type: 'scheduled',
                                     execution_date: nil
                                   ))
        expect(form).not_to be_valid
        expect(form.errors[:execution_date]).to include("can't be blank")
      end

      it 'requires execution_date to be in the future' do
        form = described_class.new(valid_attributes.merge(
                                     transaction_type: 'scheduled',
                                     execution_date: 1.day.ago
                                   ))
        expect(form).not_to be_valid
        expect(form.errors[:execution_date]).to include('must be in the future')
      end
    end
  end

  describe 'wallet validations' do
    context 'when sender wallet is missing' do
      let(:form) { described_class.new(valid_attributes.merge(sender_wallet: nil)) }

      it 'is invalid' do
        expect(form).not_to be_valid
        expect(form.errors[:sender_wallet]).to include("can't be blank")
      end
    end

    context 'when recipient wallet is missing' do
      let(:form) { described_class.new(valid_attributes.merge(recipient_wallet: nil)) }

      it 'is invalid' do
        expect(form).not_to be_valid
        expect(form.errors[:recipient_wallet]).to include("can't be blank")
      end
    end

    context 'when sender wallet is inactive' do
      let(:inactive_wallet) { create(:wallet, :inactive) }
      let(:form) { described_class.new(valid_attributes.merge(sender_wallet: inactive_wallet)) }

      it 'is invalid' do
        expect(form).not_to be_valid
        expect(form.errors[:sender_wallet]).to include('is invalid')
      end
    end

    context 'when same wallet' do
      let(:form) { described_class.new(valid_attributes.merge(recipient_wallet: sender_wallet)) }

      it 'is invalid' do
        expect(form).not_to be_valid
        expect(form.errors[:base]).to include('Sender and recipient wallets cannot be the same')
      end
    end
  end

  describe 'currency validations' do
    context 'with different currencies' do
      let(:eur_wallet) { create(:wallet, :eur) }
      let(:form) { described_class.new(valid_attributes.merge(recipient_wallet: eur_wallet)) }

      it 'is invalid' do
        expect(form).not_to be_valid
        expect(form.errors[:base]).to include('All wallets must use the same currency')
      end
    end
  end

  describe 'balance validations' do
    context 'with insufficient funds' do
      let(:form) { described_class.new(valid_attributes.merge(amount: 2000)) }

      it 'is invalid' do
        expect(form).not_to be_valid
        expect(form.errors[:amount]).to include('Insufficient funds in sender\'s wallet')
      end
    end
  end

  describe '#save' do
    context 'with valid attributes' do
      let(:form) { described_class.new(valid_attributes) }

      it 'creates a new transaction' do
        expect { form.save }.to change(Transaction, :count).by(1)
      end

      it 'returns true' do
        expect(form.save).to be true
      end

      it 'sets the correct attributes' do
        form.save
        transaction = form.result

        expect(transaction).to have_attributes(
          amount: 100,
          currency: 'USD',
          transaction_type: 'immediate',
          sender: sender,
          sender_wallet: sender_wallet,
          recipient_wallet: recipient_wallet
        )
      end
    end

    context 'with invalid attributes' do
      let(:form) { described_class.new(valid_attributes.merge(amount: 0)) }

      it 'does not create a transaction' do
        expect { form.save }.not_to change(Transaction, :count)
      end

      it 'returns false' do
        expect(form.save).to be false
      end
    end
  end

  describe 'defaults' do
    context 'when currency is not specified' do
      let(:form) { described_class.new(valid_attributes.except(:currency)) }

      it 'uses sender wallet currency' do
        expect(form.currency).to eq('USD')
      end
    end
  end
end
