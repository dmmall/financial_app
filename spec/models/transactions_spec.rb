# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transaction, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:sender).class_name('User') }
    it { is_expected.to belong_to(:sender_wallet).class_name('Wallet') }
    it { is_expected.to belong_to(:recipient_wallet).class_name('Wallet') }
  end

  describe 'validations' do
    context 'when immediate' do
      subject { build(:transaction) }
      it { is_expected.not_to validate_presence_of(:execution_date) }
    end
  end

  describe 'state machine' do
    let(:transaction) { create(:transaction) }

    describe 'initial state' do
      it 'starts in pending state' do
        expect(transaction).to be_pending
      end
    end

    describe 'transitions' do
      context 'when processing' do
        it 'transitions from pending to processing' do
          expect(transaction).to transition_from(:pending).to(:processing).on_event(:process)
        end
      end

      context 'when completing' do
        let(:transaction) { create(:transaction, :processing) }

        it 'transitions from processing to completed' do
          expect(transaction).to transition_from(:processing).to(:completed).on_event(:complete)
        end
      end

      context 'when canceling' do
        it 'can be canceled from pending' do
          expect(transaction).to transition_from(:pending).to(:canceled).on_event(:cancel)
        end

        it 'can be canceled from processing' do
          transaction.process!
          expect(transaction).to transition_from(:processing).to(:canceled).on_event(:cancel)
        end
      end

      context 'when failing' do
        it 'can fail from pending' do
          expect(transaction).to transition_from(:pending).to(:failed).on_event(:fail)
        end

        it 'can fail from processing' do
          transaction.process!
          expect(transaction).to transition_from(:processing).to(:failed).on_event(:fail)
        end
      end
    end

    describe 'logging' do
      it 'logs state changes' do
        expect(Rails.logger).to receive(:info).with(/Transaction .* changed from pending to processing/)
        transaction.process!
      end
    end
  end
end
