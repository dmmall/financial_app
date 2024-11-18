class CreateWallet < ActiveRecord::Migration[7.1]
  def change
    create_table :wallets do |t|
      t.string :currency, null: false
      t.decimal :balance, precision: 10, scale: 2, null: false, default: 0
      t.references :user, foreign_key: true
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_check_constraint :wallets, "balance >= 0", name: "balance_non_negative"
    add_check_constraint :wallets, "currency IN ('USD', 'EUR')", name: "currency_valid"
  end
end