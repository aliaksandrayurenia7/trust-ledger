class CreateLedgerTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :ledger_transactions do |t|
      t.references :order, null: false, foreign_key: true
      t.string :kind, limit: 32, null: false
      t.string :idempotency_key, limit: 128, null: false
      t.timestamps
    end

    add_index :ledger_transactions, :idempotency_key, unique: true
  end
end
