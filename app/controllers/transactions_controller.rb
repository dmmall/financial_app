# frozen_string_literal: true

class TransactionsController < ApplicationController
  before_action :fetch_transaction, only: :cancel
  before_action :set_decorated_wallets, only: %i[index new create]

  def index
    @transaction = Transaction.new
    @transactions = TransactionRepository.new.find_for_user(current_user)
  end

  def new
    @transaction = Transaction.new
  end

  def create
    @transaction = Transactions::Creator.call(transaction_params.merge(
                                                sender: current_user,
                                                sender_wallet: sender_wallet,
                                                recipient_wallet: recipient_wallet
                                              ))
    respond_to do |format|
      @alert = @transaction.errors.full_messages.to_sentence
      format.turbo_stream
      format.html { redirect_to transactions_path }
    end
  rescue StandardError => e
    @alert = e.message
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to transactions_path }
    end
  end

  def cancel
    service = Transactions::Canceler.new(@transaction)

    if service.call
      respond_to do |format|
        format.html { redirect_to transactions_path, notice: 'Transaction was successfully canceled.' }
        format.turbo_stream { render turbo_stream: turbo_stream.remove(@transaction) }
      end
    else
      redirect_to transactions_path, alert: service.errors.full_messages.to_sentence
    end
  end

  private

  def set_decorated_wallets
    @wallets = WalletDecorator.decorate_collection(available_wallets)
  end

  def available_wallets
    @available_wallets ||= WalletRepository.new.available_for_user(
      current_user,
      currency: params[:currency]
    )
  end

  def fetch_transaction
    @transaction = Transaction.find(params[:id])
  end

  def recipient_wallet
    @recipient_wallet ||= Wallet.find(transaction_params[:recipient_wallet_id])
  end

  def sender_wallet
    current_user.wallet(recipient_wallet.currency)
  end

  def transaction_params
    params.require(:transaction).permit(
      :recipient_wallet_id,
      :amount,
      :currency,
      :transaction_type,
      :execution_date
    )
  end
end
