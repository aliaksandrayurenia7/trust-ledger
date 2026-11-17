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

ActiveRecord::Schema[8.1].define(version: 2026_11_17_000007) do
  create_table "disputes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.string "opened_by", limit: 16, null: false
    t.string "reason_code", limit: 64, null: false
    t.string "state", limit: 16, default: "open", null: false
    t.string "resolution", limit: 16
    t.bigint "assigned_support_id"
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_support_id"], name: "index_disputes_on_assigned_support_id"
    t.index ["order_id"], name: "index_disputes_on_order_id"
    t.index ["state"], name: "index_disputes_on_state"
  end

  create_table "ledger_entries", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "ledger_transaction_id", null: false
    t.string "account", limit: 64, null: false
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.index ["account"], name: "index_ledger_entries_on_account"
    t.index ["ledger_transaction_id"], name: "index_ledger_entries_on_ledger_transaction_id"
  end

  create_table "ledger_transactions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.string "kind", limit: 32, null: false
    t.string "idempotency_key", limit: 128, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["idempotency_key"], name: "index_ledger_transactions_on_idempotency_key", unique: true
    t.index ["order_id"], name: "index_ledger_transactions_on_order_id"
  end

  create_table "order_events", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.string "from_state", limit: 32
    t.string "to_state", limit: 32, null: false
    t.string "actor_type", limit: 16, null: false
    t.bigint "actor_id"
    t.string "reason_code", limit: 64
    t.text "note"
    t.datetime "created_at", null: false
    t.index ["order_id", "created_at"], name: "index_order_events_on_order_id_and_created_at"
    t.index ["order_id"], name: "index_order_events_on_order_id"
  end

  create_table "orders", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "buyer_id", null: false
    t.bigint "seller_id", null: false
    t.integer "amount_cents", null: false
    t.string "currency", limit: 3, default: "EUR", null: false
    t.string "state", limit: 32, default: "created", null: false
    t.integer "risk_score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id"], name: "index_orders_on_buyer_id"
    t.index ["seller_id"], name: "index_orders_on_seller_id"
    t.index ["state"], name: "index_orders_on_state"
  end

  create_table "risk_checks", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.string "rule_code", limit: 64, null: false
    t.integer "points", null: false
    t.json "details"
    t.datetime "created_at", null: false
    t.index ["order_id"], name: "index_risk_checks_on_order_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "role", limit: 16, null: false
    t.string "country", limit: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "disputes", "orders"
  add_foreign_key "disputes", "users", column: "assigned_support_id"
  add_foreign_key "ledger_entries", "ledger_transactions"
  add_foreign_key "ledger_transactions", "orders"
  add_foreign_key "order_events", "orders"
  add_foreign_key "orders", "users", column: "buyer_id"
  add_foreign_key "orders", "users", column: "seller_id"
  add_foreign_key "risk_checks", "orders"
end
