# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_11_17_195547) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "transactions", force: :cascade do |t|
    t.bigint "sender_id"
    t.bigint "sender_wallet_id"
    t.bigint "recipient_wallet_id"
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "currency", null: false
    t.datetime "execution_date"
    t.datetime "completed_at"
    t.integer "status", default: 0
    t.integer "transaction_type", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipient_wallet_id"], name: "index_transactions_on_recipient_wallet_id"
    t.index ["sender_id"], name: "index_transactions_on_sender_id"
    t.index ["sender_wallet_id"], name: "index_transactions_on_sender_wallet_id"
    t.check_constraint "amount > 0::numeric", name: "amount_positive"
    t.check_constraint "currency::text = ANY (ARRAY['USD'::character varying, 'EUR'::character varying]::text[])", name: "currency_valid"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "wallets", force: :cascade do |t|
    t.string "currency", null: false
    t.decimal "balance", precision: 10, scale: 2, default: "0.0", null: false
    t.bigint "user_id"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_wallets_on_user_id"
    t.check_constraint "balance >= 0::numeric", name: "balance_non_negative"
    t.check_constraint "currency::text = ANY (ARRAY['USD'::character varying, 'EUR'::character varying]::text[])", name: "currency_valid"
  end

  add_foreign_key "transactions", "users", column: "sender_id"
  add_foreign_key "transactions", "wallets", column: "recipient_wallet_id"
  add_foreign_key "transactions", "wallets", column: "sender_wallet_id"
  add_foreign_key "wallets", "users"
end
