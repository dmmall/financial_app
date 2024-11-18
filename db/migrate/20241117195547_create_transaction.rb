class CreateTransaction < ActiveRecord::Migration[7.1]
  def change
    create_table :transactions do |t|
      t.references :sender, foreign_key: { to_table: :users }
      t.references :sender_wallet, foreign_key: { to_table: :wallets }
      t.references :recipient_wallet, foreign_key: { to_table: :wallets }
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :currency, null: false
      t.datetime :execution_date
      t.datetime :completed_at
      t.integer :status, default: 0
      t.integer :transaction_type, default: 0

      t.timestamps
    end

    add_check_constraint :transactions, "amount > 0", name: "amount_positive"
    add_check_constraint :transactions, "currency IN ('USD', 'EUR')", name: "currency_valid"
  end
end
